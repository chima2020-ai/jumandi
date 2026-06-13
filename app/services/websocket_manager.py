import json
from typing import Any

from fastapi import WebSocket


class ConnectionManager:
    """Manages WebSocket connections for real-time notifications and tracking."""

    def __init__(self):
        self.active_connections: dict[int, list[WebSocket]] = {}
        self.user_roles: dict[int, str] = {}
        self.booking_subscribers: dict[int, list[WebSocket]] = {}

    async def connect_user(self, user_id: int, role: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.setdefault(user_id, []).append(websocket)
        self.user_roles[user_id] = role

    def disconnect_user(self, user_id: int, websocket: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id] = [
                ws for ws in self.active_connections[user_id] if ws != websocket
            ]
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
                self.user_roles.pop(user_id, None)

    async def subscribe_booking(self, booking_id: int, websocket: WebSocket):
        await websocket.accept()
        self.booking_subscribers.setdefault(booking_id, []).append(websocket)

    def unsubscribe_booking(self, booking_id: int, websocket: WebSocket):
        if booking_id in self.booking_subscribers:
            self.booking_subscribers[booking_id] = [
                ws for ws in self.booking_subscribers[booking_id] if ws != websocket
            ]
            if not self.booking_subscribers[booking_id]:
                del self.booking_subscribers[booking_id]

    async def send_to_user(self, user_id: int, message: dict[str, Any]):
        for websocket in self.active_connections.get(user_id, []):
            try:
                await websocket.send_json(message)
            except Exception:
                pass

    async def broadcast_to_delivery_agents(self, message: dict[str, Any]):
        """Notify all connected delivery agents about a new booking."""
        for user_id, sockets in self.active_connections.items():
            if self.user_roles.get(user_id) != "delivery":
                continue
            for websocket in sockets:
                try:
                    await websocket.send_json(message)
                except Exception:
                    pass

    async def broadcast_booking_update(self, booking_id: int, message: dict[str, Any]):
        """Send updates to everyone watching a specific booking (for map tracking)."""
        for websocket in self.booking_subscribers.get(booking_id, []):
            try:
                await websocket.send_json(message)
            except Exception:
                pass


manager = ConnectionManager()
