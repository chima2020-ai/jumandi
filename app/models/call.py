import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class CallStatus(str, enum.Enum):
    INITIATED = "initiated"
    COMPLETED = "completed"
    MISSED = "missed"


class CallLog(Base):
    __tablename__ = "call_logs"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    booking_id: Mapped[int] = mapped_column(ForeignKey("bookings.id"), index=True)
    caller_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    receiver_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    status: Mapped[CallStatus] = mapped_column(
        Enum(CallStatus), default=CallStatus.INITIATED, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    booking = relationship("Booking", foreign_keys=[booking_id])
    caller = relationship("User", foreign_keys=[caller_id])
    receiver = relationship("User", foreign_keys=[receiver_id])
