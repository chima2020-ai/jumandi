from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.booking import Booking, BookingStatus
from app.models.user import User, UserRole
from app.schemas.booking import BookingResponse, LocationUpdate
from app.services.websocket_manager import manager
from app.utils.auth import require_role

router = APIRouter(prefix="/delivery", tags=["Delivery"])


@router.get("/pending", response_model=list[BookingResponse])
def get_pending_bookings(
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    """Delivery agents see all pending bookings waiting to be accepted."""
    return (
        db.query(Booking)
        .options(joinedload(Booking.customer))
        .filter(Booking.status == BookingStatus.PENDING)
        .order_by(Booking.created_at.asc())
        .all()
    )


@router.get("/my", response_model=list[BookingResponse])
def get_my_deliveries(
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    """Delivery agent views their assigned bookings."""
    return (
        db.query(Booking)
        .options(joinedload(Booking.customer))
        .filter(Booking.delivery_agent_id == user.id)
        .order_by(Booking.created_at.desc())
        .all()
    )


@router.post("/{booking_id}/accept", response_model=BookingResponse)
async def accept_booking(
    booking_id: int,
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status != BookingStatus.PENDING:
        raise HTTPException(status_code=400, detail="Booking is no longer available")

    booking.status = BookingStatus.ACCEPTED
    booking.delivery_agent_id = user.id
    booking.accepted_at = datetime.now(timezone.utc)
    db.commit()

    booking = (
        db.query(Booking)
        .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
        .filter(Booking.id == booking_id)
        .first()
    )

    await manager.send_to_user(
        booking.customer_id,
        {
            "type": "booking_accepted",
            "booking": BookingResponse.model_validate(booking).model_dump(mode="json"),
        },
    )

    return booking


@router.post("/{booking_id}/decline", response_model=BookingResponse)
async def decline_booking(
    booking_id: int,
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    """Decline a booking. Booking stays pending for other agents."""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status != BookingStatus.PENDING:
        raise HTTPException(status_code=400, detail="Booking is no longer available")

    return booking


@router.post("/{booking_id}/start", response_model=BookingResponse)
async def start_delivery(
    booking_id: int,
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    """Mark delivery as in transit — customer can now track on map."""
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking or booking.delivery_agent_id != user.id:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status != BookingStatus.ACCEPTED:
        raise HTTPException(status_code=400, detail="Booking must be accepted first")

    booking.status = BookingStatus.IN_TRANSIT
    db.commit()
    db.refresh(booking)

    await manager.send_to_user(
        booking.customer_id,
        {
            "type": "delivery_started",
            "booking_id": booking.id,
        },
    )

    return booking


@router.post("/{booking_id}/complete", response_model=BookingResponse)
async def complete_delivery(
    booking_id: int,
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking or booking.delivery_agent_id != user.id:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status != BookingStatus.IN_TRANSIT:
        raise HTTPException(status_code=400, detail="Delivery must be in transit")

    booking.status = BookingStatus.DELIVERED
    booking.delivered_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(booking)

    await manager.send_to_user(
        booking.customer_id,
        {
            "type": "delivery_completed",
            "booking_id": booking.id,
        },
    )

    return booking


@router.post("/location", status_code=status.HTTP_200_OK)
async def update_location(
    data: LocationUpdate,
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    """Delivery agent sends their current GPS location."""
    user.current_lat = data.latitude
    user.current_lng = data.longitude
    db.commit()

    active_bookings = (
        db.query(Booking)
        .filter(
            Booking.delivery_agent_id == user.id,
            Booking.status == BookingStatus.IN_TRANSIT,
        )
        .all()
    )

    for booking in active_bookings:
        await manager.broadcast_booking_update(
            booking.id,
            {
                "type": "location_update",
                "booking_id": booking.id,
                "delivery_agent_id": user.id,
                "latitude": data.latitude,
                "longitude": data.longitude,
            },
        )

    return {"message": "Location updated"}


@router.patch("/availability")
def toggle_availability(
    is_available: bool,
    user: User = Depends(require_role(UserRole.DELIVERY)),
    db: Session = Depends(get_db),
):
    user.is_available = is_available
    db.commit()
    return {"is_available": user.is_available}
