from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import SessionLocal
from app.models.booking import Booking
from app.models.user import User, UserRole
from app.services.websocket_manager import manager

router = APIRouter(tags=["WebSocket"])


def get_user_from_token(token: str, db: Session) -> User | None:
    try:
        payload = jwt.decode(
            token, settings.secret_key, algorithms=[settings.algorithm]
        )
        user_id = int(payload.get("sub"))
        return db.query(User).filter(User.id == user_id).first()
    except (JWTError, TypeError, ValueError):
        return None


@router.websocket("/ws/notifications")
async def notifications_websocket(websocket: WebSocket, token: str):
    """
    Real-time notifications for users and delivery agents.
    Connect with: ws://host/ws/notifications?token=YOUR_JWT_TOKEN

  - Customers receive: booking_accepted, delivery_started, delivery_completed
  - Delivery agents receive: new_booking, booking_cancelled
    """
    db = SessionLocal()
    try:
        user = get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001)
            return

        await manager.connect_user(user.id, user.role.value, websocket)
        await websocket.send_json(
            {"type": "connected", "user_id": user.id, "role": user.role.value}
        )

        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_user(user.id, websocket)
    finally:
        db.close()


@router.websocket("/ws/tracking/{booking_id}")
async def tracking_websocket(websocket: WebSocket, booking_id: int, token: str):
    """
    Live map tracking for a booking.
    Customer connects here to see delivery agent movement in real time.
    Connect with: ws://host/ws/tracking/1?token=YOUR_JWT_TOKEN
    """
    db = SessionLocal()
    try:
        user = get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001)
            return

        booking = db.query(Booking).filter(Booking.id == booking_id).first()
        if not booking:
            await websocket.close(code=4004)
            return

        if user.role == UserRole.CUSTOMER and booking.customer_id != user.id:
            await websocket.close(code=4003)
            return
        if user.role == UserRole.DELIVERY and booking.delivery_agent_id != user.id:
            await websocket.close(code=4003)
            return

        await manager.subscribe_booking(booking_id, websocket)

        if booking.delivery_agent and booking.delivery_agent.current_lat:
            await websocket.send_json(
                {
                    "type": "location_update",
                    "booking_id": booking_id,
                    "delivery_agent_id": booking.delivery_agent_id,
                    "latitude": booking.delivery_agent.current_lat,
                    "longitude": booking.delivery_agent.current_lng,
                }
            )

        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.unsubscribe_booking(booking_id, websocket)
    finally:
        db.close()
