from datetime import datetime

from pydantic import BaseModel, Field

from app.models.call import CallStatus
from app.models.user import UserRole


class CallContactResponse(BaseModel):
    booking_id: int
    contact_id: int
    contact_name: str
    contact_phone: str
    contact_role: UserRole
    tel_uri: str


class CallInitiateResponse(BaseModel):
    call_id: int
    booking_id: int
    contact_name: str
    contact_phone: str
    tel_uri: str
    message: str = "Call initiated. Use your phone dialer to connect."


class CallLogResponse(BaseModel):
    id: int
    booking_id: int
    caller_id: int
    caller_name: str
    receiver_id: int
    receiver_name: str
    status: CallStatus
    created_at: datetime

    model_config = {"from_attributes": True}


class CallStatusUpdate(BaseModel):
    status: CallStatus = Field(description="Update call status to completed or missed")
