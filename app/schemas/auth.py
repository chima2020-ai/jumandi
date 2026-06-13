from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.models.user import UserRole


class UserRegister(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(min_length=7, max_length=20)
    password: str = Field(min_length=6)
    role: UserRole


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    role: UserRole
    is_available: bool
    is_verified: bool = False
    current_lat: float | None = None
    current_lng: float | None = None

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    phone: str | None = Field(default=None, min_length=7, max_length=20)


class OtpVerify(BaseModel):
    code: str = Field(min_length=4, max_length=6)


class ForgotPassword(BaseModel):
    email: EmailStr


class ResetPassword(BaseModel):
    email: EmailStr
    token: str = Field(min_length=4, max_length=64)
    new_password: str = Field(min_length=6)


class MessageResponse(BaseModel):
    id: int
    booking_id: int
    sender_id: int
    sender_name: str
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
