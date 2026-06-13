from datetime import datetime

from pydantic import BaseModel, Field

from app.models.booking import BookingStatus
from app.schemas.auth import UserResponse


class BookingCreate(BaseModel):
    gas_kg: float = Field(gt=0, description="Gas quantity in kg")
    address: str = Field(min_length=5)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    notes: str | None = None


class BookingResponse(BaseModel):
    id: int
    customer_id: int
    delivery_agent_id: int | None
    gas_kg: float
    address: str
    latitude: float
    longitude: float
    notes: str | None
    status: BookingStatus
    created_at: datetime
    accepted_at: datetime | None
    delivered_at: datetime | None
    customer: UserResponse | None = None
    delivery_agent: UserResponse | None = None

    model_config = {"from_attributes": True}


class BookingStatusUpdate(BaseModel):
    status: BookingStatus


class LocationUpdate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
