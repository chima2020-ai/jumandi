from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.schemas.auth import UserResponse
from app.schemas.booking import BookingResponse


class AdminCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(min_length=7, max_length=20)
    password: str = Field(min_length=6)


class AdminSetupStatus(BaseModel):
    needs_setup: bool
    admin_count: int


class AdminOverview(BaseModel):
    customers: int
    drivers: int
    drivers_online: int
    admins: int
    bookings_total: int
    bookings_pending: int
    bookings_active: int
    bookings_delivered: int
    bookings_cancelled: int
    gas_kg_delivered: float
    messages_total: int
    calls_total: int


class CustomerListResponse(BaseModel):
    customers: list[UserResponse]
    total: int


class BookingListResponse(BaseModel):
    bookings: list[BookingResponse]
    total: int


class ActivityItem(BaseModel):
    type: str
    message: str
    created_at: datetime
    booking_id: int | None = None


class ActivityFeedResponse(BaseModel):
    items: list[ActivityItem]


class DeliveryAgentCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(min_length=7, max_length=20)
    password: str = Field(min_length=6)


class DeliveryAgentUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    phone: str | None = Field(default=None, min_length=7, max_length=20)
    password: str | None = Field(default=None, min_length=6)
    is_available: bool | None = None


class DeliveryAgentListResponse(BaseModel):
    agents: list[UserResponse]
    total: int
