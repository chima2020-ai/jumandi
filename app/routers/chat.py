from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.models.booking import Booking, BookingStatus
from app.models.message import Message
from app.models.user import User, UserRole
from app.schemas.auth import (
    ChatConversationResponse,
    MarkReadResponse,
    MessageCreate,
    MessageResponse,
    TypingRequest,
)
from app.services.websocket_manager import manager
from app.utils.auth import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])

_CHAT_STATUSES = (BookingStatus.ACCEPTED, BookingStatus.IN_TRANSIT)


def _message_to_response(message: Message) -> MessageResponse:
    return MessageResponse(
        id=message.id,
        booking_id=message.booking_id,
        sender_id=message.sender_id,
        sender_name=message.sender.name,
        content=message.content,
        created_at=message.created_at,
        read_at=message.read_at,
    )


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


def _ensure_chat_allowed(booking: Booking) -> None:
    if booking.delivery_agent_id is None:
        raise HTTPException(status_code=400, detail="Chat opens after a driver accepts")
    if booking.status not in _CHAT_STATUSES:
        raise HTTPException(status_code=400, detail="Chat is not available for this order status")


def _other_user_id(booking: Booking, user: User) -> int:
    if user.role == UserRole.CUSTOMER:
        return booking.delivery_agent_id  # type: ignore[return-value]
    return booking.customer_id


@router.get("/conversations", response_model=list[ChatConversationResponse])
def list_conversations(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.role == UserRole.CUSTOMER:
        bookings = (
            db.query(Booking)
            .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
            .filter(
                Booking.customer_id == user.id,
                Booking.delivery_agent_id.isnot(None),
                Booking.status.in_(_CHAT_STATUSES),
            )
            .all()
        )
    elif user.role == UserRole.DELIVERY:
        bookings = (
            db.query(Booking)
            .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
            .filter(
                Booking.delivery_agent_id == user.id,
                Booking.status.in_(_CHAT_STATUSES),
            )
            .all()
        )
    else:
        return []

    conversations: list[ChatConversationResponse] = []
    for booking in bookings:
        other = booking.delivery_agent if user.role == UserRole.CUSTOMER else booking.customer
        if other is None:
            continue

        last_message = (
            db.query(Message)
            .filter(Message.booking_id == booking.id)
            .order_by(Message.created_at.desc())
            .first()
        )
        unread_count = (
            db.query(func.count(Message.id))
            .filter(
                Message.booking_id == booking.id,
                Message.sender_id != user.id,
                Message.read_at.is_(None),
            )
            .scalar()
            or 0
        )

        conversations.append(
            ChatConversationResponse(
                booking_id=booking.id,
                other_user_id=other.id,
                other_user_name=other.name,
                booking_status=booking.status.value,
                last_message=last_message.content if last_message else None,
                last_message_at=last_message.created_at if last_message else None,
                unread_count=int(unread_count),
            )
        )

    conversations.sort(
        key=lambda c: c.last_message_at or datetime.min,
        reverse=True,
    )
    return conversations


@router.get("/{booking_id}/messages", response_model=list[MessageResponse])
def list_messages(
    booking_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    booking = _get_booking_for_user(booking_id, user, db)
    _ensure_chat_allowed(booking)
    messages = (
        db.query(Message)
        .options(joinedload(Message.sender))
        .filter(Message.booking_id == booking_id)
        .order_by(Message.created_at.asc())
        .all()
    )
    return [_message_to_response(message) for message in messages]


@router.post(
    "/{booking_id}/messages",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def send_message(
    booking_id: int,
    data: MessageCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    booking = _get_booking_for_user(booking_id, user, db)
    _ensure_chat_allowed(booking)

    message = Message(
        booking_id=booking_id,
        sender_id=user.id,
        content=data.content.strip(),
    )
    db.add(message)
    db.commit()
    message = (
        db.query(Message)
        .options(joinedload(Message.sender))
        .filter(Message.id == message.id)
        .first()
    )

    response = _message_to_response(message)
    recipient_id = _other_user_id(booking, user)
    await manager.send_to_user(
        recipient_id,
        {
            "type": "new_message",
            "booking_id": booking_id,
            "message": response.model_dump(mode="json"),
        },
    )
    return response


@router.post("/{booking_id}/read", response_model=MarkReadResponse)
async def mark_messages_read(
    booking_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    booking = _get_booking_for_user(booking_id, user, db)
    _ensure_chat_allowed(booking)

    now = datetime.now(UTC).replace(tzinfo=None)
    updated = (
        db.query(Message)
        .filter(
            Message.booking_id == booking_id,
            Message.sender_id != user.id,
            Message.read_at.is_(None),
        )
        .update({Message.read_at: now}, synchronize_session=False)
    )
    db.commit()

    if updated:
        sender_id = _other_user_id(booking, user)
        await manager.send_to_user(
            sender_id,
            {
                "type": "messages_read",
                "booking_id": booking_id,
                "read_at": now.isoformat(),
                "reader_id": user.id,
            },
        )

    return MarkReadResponse(updated=updated)


@router.post("/{booking_id}/typing")
async def send_typing(
    booking_id: int,
    data: TypingRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    booking = _get_booking_for_user(booking_id, user, db)
    _ensure_chat_allowed(booking)

    recipient_id = _other_user_id(booking, user)
    await manager.send_to_user(
        recipient_id,
        {
            "type": "typing",
            "booking_id": booking_id,
            "user_id": user.id,
            "user_name": user.name,
            "is_typing": data.is_typing,
        },
    )
    return {"message": "ok"}
