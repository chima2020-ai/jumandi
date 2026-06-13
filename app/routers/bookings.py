from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.booking import Booking, BookingStatus
from app.models.user import User, UserRole
from app.schemas.booking import BookingCreate, BookingResponse
from app.services.websocket_manager import manager
from app.utils.auth import require_role

router = APIRouter(prefix="/bookings", tags=["Bookings"])


@router.post("", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_booking(
    data: BookingCreate,
    user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
):
    """Customer books gas delivery with location and kg amount."""
    booking = Booking(
        customer_id=user.id,
        gas_kg=data.gas_kg,
        address=data.address,
        latitude=data.latitude,
        longitude=data.longitude,
        notes=data.notes,
        status=BookingStatus.PENDING,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)

    booking = (
        db.query(Booking)
        .options(joinedload(Booking.customer))
        .filter(Booking.id == booking.id)
        .first()
    )

    await manager.broadcast_to_delivery_agents(
        {
            "type": "new_booking",
            "booking": BookingResponse.model_validate(booking).model_dump(mode="json"),
        }
    )

    return booking


@router.get("/my", response_model=list[BookingResponse])
def get_my_bookings(
    user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
):
    """Customer views their booking history."""
    return (
        db.query(Booking)
        .options(joinedload(Booking.delivery_agent))
        .filter(Booking.customer_id == user.id)
        .order_by(Booking.created_at.desc())
        .all()
    )


@router.get("/{booking_id}", response_model=BookingResponse)
def get_booking(
    booking_id: int,
    user: User = Depends(require_role(UserRole.CUSTOMER, UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    booking = (
        db.query(Booking)
        .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
        .filter(Booking.id == booking_id)
        .first()
    )
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    if user.role == UserRole.CUSTOMER and booking.customer_id != user.id:
        raise HTTPException(status_code=403, detail="Not your booking")
    if user.role == UserRole.DELIVERY and booking.delivery_agent_id not in (
        None,
        user.id,
    ):
        raise HTTPException(status_code=403, detail="Not assigned to this booking")

    return booking


@router.post("/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_booking(
    booking_id: int,
    user: User = Depends(require_role(UserRole.CUSTOMER)),
    db: Session = Depends(get_db),
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking or booking.customer_id != user.id:
        raise HTTPException(status_code=404, detail="Booking not found")

    if booking.status not in (BookingStatus.PENDING, BookingStatus.ACCEPTED):
        raise HTTPException(
            status_code=400,
            detail=f"Cannot cancel a booking with status '{booking.status}'",
        )

    booking.status = BookingStatus.CANCELLED
    db.commit()
    db.refresh(booking)

    if booking.delivery_agent_id:
        await manager.send_to_user(
            booking.delivery_agent_id,
            {
                "type": "booking_cancelled",
                "booking_id": booking.id,
            },
        )

    return booking
