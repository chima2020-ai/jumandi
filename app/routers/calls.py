from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.booking import Booking, BookingStatus
from app.models.call import CallLog, CallStatus
from app.models.user import User, UserRole
from app.schemas.call import (
    CallContactResponse,
    CallInitiateResponse,
    CallLogResponse,
    CallStatusUpdate,
)
from app.services.websocket_manager import manager
from app.utils.auth import get_current_user

router = APIRouter(prefix="/calls", tags=["Calls"])

ACTIVE_STATUSES = {
    BookingStatus.PENDING,
    BookingStatus.ACCEPTED,
    BookingStatus.IN_TRANSIT,
}


def _normalize_phone(phone: str) -> str:
    return "".join(ch for ch in phone if ch.isdigit() or ch == "+")


def _get_booking(booking_id: int, db: Session) -> Booking:
    booking = (
        db.query(Booking)
        .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
        .filter(Booking.id == booking_id)
        .first()
    )
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


def _can_call_booking(booking: Booking, user: User) -> bool:
    if booking.status not in ACTIVE_STATUSES:
        return False

    if user.role == UserRole.CUSTOMER:
        return booking.customer_id == user.id and booking.delivery_agent_id is not None

    if user.role == UserRole.DELIVERY:
        if booking.delivery_agent_id == user.id:
            return True
        return booking.status == BookingStatus.PENDING

    return False


def _get_contact(booking: Booking, user: User) -> User:
    if user.role == UserRole.CUSTOMER:
        if not booking.delivery_agent:
            raise HTTPException(
                status_code=400,
                detail="No delivery agent assigned to this booking yet",
            )
        return booking.delivery_agent

    if user.role == UserRole.DELIVERY:
        return booking.customer

    raise HTTPException(status_code=403, detail="You do not have permission for this action")


@router.get("/booking/{booking_id}/contact", response_model=CallContactResponse)
def get_call_contact(
    booking_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the phone number of the other person on an active booking."""
    booking = _get_booking(booking_id, db)
    if not _can_call_booking(booking, user):
        raise HTTPException(
            status_code=403,
            detail="You cannot call for this booking right now",
        )

    contact = _get_contact(booking, user)
    phone = _normalize_phone(contact.phone)

    return CallContactResponse(
        booking_id=booking.id,
        contact_id=contact.id,
        contact_name=contact.name,
        contact_phone=contact.phone,
        contact_role=contact.role,
        tel_uri=f"tel:{phone}",
    )


@router.post(
    "/booking/{booking_id}/initiate",
    response_model=CallInitiateResponse,
    status_code=status.HTTP_201_CREATED,
)
async def initiate_call(
    booking_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Start a call to the other party on a booking.
    Logs the call and sends a real-time notification to the receiver.
    Returns a tel: URI for the mobile app to open the phone dialer.
    """
    booking = _get_booking(booking_id, db)
    if not _can_call_booking(booking, user):
        raise HTTPException(
            status_code=403,
            detail="You cannot call for this booking right now",
        )

    contact = _get_contact(booking, user)
    phone = _normalize_phone(contact.phone)

    call_log = CallLog(
        booking_id=booking.id,
        caller_id=user.id,
        receiver_id=contact.id,
        status=CallStatus.INITIATED,
    )
    db.add(call_log)
    db.commit()
    db.refresh(call_log)

    await manager.send_to_user(
        contact.id,
        {
            "type": "incoming_call",
            "booking_id": booking.id,
            "call_id": call_log.id,
            "caller_id": user.id,
            "caller_name": user.name,
            "caller_phone": user.phone,
            "message": f"{user.name} is calling about booking #{booking.id}",
        },
    )

    return CallInitiateResponse(
        call_id=call_log.id,
        booking_id=booking.id,
        contact_name=contact.name,
        contact_phone=contact.phone,
        tel_uri=f"tel:{phone}",
    )


@router.get("/booking/{booking_id}", response_model=list[CallLogResponse])
def list_booking_calls(
    booking_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List call history for a booking."""
    booking = _get_booking(booking_id, db)

    if user.role == UserRole.CUSTOMER and booking.customer_id != user.id:
        raise HTTPException(status_code=403, detail="Not your booking")
    if user.role == UserRole.DELIVERY and booking.delivery_agent_id not in (
        None,
        user.id,
    ):
        raise HTTPException(status_code=403, detail="Not assigned to this booking")

    calls = (
        db.query(CallLog)
        .options(joinedload(CallLog.caller), joinedload(CallLog.receiver))
        .filter(CallLog.booking_id == booking_id)
        .order_by(CallLog.created_at.desc())
        .all()
    )

    return [
        CallLogResponse(
            id=call.id,
            booking_id=call.booking_id,
            caller_id=call.caller_id,
            caller_name=call.caller.name,
            receiver_id=call.receiver_id,
            receiver_name=call.receiver.name,
            status=call.status,
            created_at=call.created_at,
        )
        for call in calls
    ]


@router.patch("/{call_id}/status", response_model=CallLogResponse)
def update_call_status(
    call_id: int,
    data: CallStatusUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a call as completed or missed."""
    call = (
        db.query(CallLog)
        .options(joinedload(CallLog.caller), joinedload(CallLog.receiver))
        .filter(CallLog.id == call_id)
        .first()
    )
    if not call:
        raise HTTPException(status_code=404, detail="Call not found")

    if user.id not in (call.caller_id, call.receiver_id):
        raise HTTPException(status_code=403, detail="Not part of this call")

    if data.status not in (CallStatus.COMPLETED, CallStatus.MISSED):
        raise HTTPException(status_code=400, detail="Status must be completed or missed")

    call.status = data.status
    db.commit()
    db.refresh(call)

    return CallLogResponse(
        id=call.id,
        booking_id=call.booking_id,
        caller_id=call.caller_id,
        caller_name=call.caller.name,
        receiver_id=call.receiver_id,
        receiver_name=call.receiver.name,
        status=call.status,
        created_at=call.created_at,
    )
