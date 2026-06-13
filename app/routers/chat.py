from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.booking import Booking
from app.models.message import Message
from app.models.user import User, UserRole
from app.schemas.auth import MessageCreate, MessageResponse
from app.utils.auth import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])


def _get_booking_for_user(booking_id: int, user: User, db: Session) -> Booking:
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
    if user.role == UserRole.DELIVERY and booking.delivery_agent_id != user.id:
        raise HTTPException(status_code=403, detail="Not assigned to this booking")

    return booking


@router.get("/{booking_id}/messages", response_model=list[MessageResponse])
def list_messages(
    booking_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _get_booking_for_user(booking_id, user, db)
    messages = (
        db.query(Message)
        .options(joinedload(Message.sender))
        .filter(Message.booking_id == booking_id)
        .order_by(Message.created_at.asc())
        .all()
    )
    return [
        MessageResponse(
            id=message.id,
            booking_id=message.booking_id,
            sender_id=message.sender_id,
            sender_name=message.sender.name,
            content=message.content,
            created_at=message.created_at,
        )
        for message in messages
    ]


@router.post(
    "/{booking_id}/messages",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
)
def send_message(
    booking_id: int,
    data: MessageCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _get_booking_for_user(booking_id, user, db)
    message = Message(
        booking_id=booking_id,
        sender_id=user.id,
        content=data.content.strip(),
    )
    db.add(message)
    db.commit()
    db.refresh(message)

    return MessageResponse(
        id=message.id,
        booking_id=message.booking_id,
        sender_id=message.sender_id,
        sender_name=user.name,
        content=message.content,
        created_at=message.created_at,
    )
