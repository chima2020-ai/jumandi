from pydantic import BaseModel, EmailStr, Field

from app.schemas.auth import UserResponse


class AdminCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(min_length=7, max_length=20)
    password: str = Field(min_length=6)


class AdminSetupStatus(BaseModel):
    needs_setup: bool
    admin_count: int


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
