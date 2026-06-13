from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.booking import Booking, BookingStatus
from app.models.user import User, UserRole
from app.schemas.admin import (
    AdminCreate,
    AdminSetupStatus,
    DeliveryAgentCreate,
    DeliveryAgentListResponse,
    DeliveryAgentUpdate,
)
from app.schemas.auth import UserResponse
from app.utils.auth import hash_password, require_role

router = APIRouter(prefix="/admin", tags=["Admin"])


def _admin_count(db: Session) -> int:
    return db.query(User).filter(User.role == UserRole.ADMIN).count()


@router.get("/setup/status", response_model=AdminSetupStatus)
def admin_setup_status(db: Session = Depends(get_db)):
    count = _admin_count(db)
    return AdminSetupStatus(needs_setup=count == 0, admin_count=count)


@router.post("/setup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def setup_first_admin(data: AdminCreate, db: Session = Depends(get_db)):
    """Create the first admin account when none exist yet."""
    if _admin_count(db) > 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin account already exists. Please log in instead.",
        )

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    admin = User(
        name=data.name,
        email=data.email,
        phone=data.phone,
        hashed_password=hash_password(data.password),
        role=UserRole.ADMIN,
        is_verified=True,
        is_available=True,
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    return admin


@router.post("/admins", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_admin(
    data: AdminCreate,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    admin = User(
        name=data.name,
        email=data.email,
        phone=data.phone,
        hashed_password=hash_password(data.password),
        role=UserRole.ADMIN,
        is_verified=True,
        is_available=True,
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    return admin


@router.get("/delivery-agents", response_model=DeliveryAgentListResponse)
def list_delivery_agents(
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    agents = (
        db.query(User)
        .filter(User.role == UserRole.DELIVERY)
        .order_by(User.id.desc())
        .all()
    )
    return DeliveryAgentListResponse(
        agents=[UserResponse.model_validate(agent) for agent in agents],
        total=len(agents),
    )


@router.post(
    "/delivery-agents",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_delivery_agent(
    data: DeliveryAgentCreate,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    agent = User(
        name=data.name,
        email=data.email,
        phone=data.phone,
        hashed_password=hash_password(data.password),
        role=UserRole.DELIVERY,
        is_verified=True,
        is_available=True,
    )
    db.add(agent)
    db.commit()
    db.refresh(agent)
    return agent


@router.patch("/delivery-agents/{agent_id}", response_model=UserResponse)
def update_delivery_agent(
    agent_id: int,
    data: DeliveryAgentUpdate,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    agent = db.query(User).filter(User.id == agent_id, User.role == UserRole.DELIVERY).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Delivery agent not found")

    if data.name is not None:
        agent.name = data.name
    if data.phone is not None:
        agent.phone = data.phone
    if data.password is not None:
        agent.hashed_password = hash_password(data.password)
    if data.is_available is not None:
        agent.is_available = data.is_available

    db.commit()
    db.refresh(agent)
    return agent


@router.delete("/delivery-agents/{agent_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_delivery_agent(
    agent_id: int,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    agent = db.query(User).filter(User.id == agent_id, User.role == UserRole.DELIVERY).first()
    if not agent:
        raise HTTPException(status_code=404, detail="Delivery agent not found")

    active = (
        db.query(Booking)
        .filter(
            Booking.delivery_agent_id == agent_id,
            Booking.status.in_(
                [BookingStatus.PENDING, BookingStatus.ACCEPTED, BookingStatus.IN_TRANSIT]
            ),
        )
        .first()
    )
    if active:
        raise HTTPException(
            status_code=400,
            detail="Cannot delete agent with active bookings",
        )

    db.delete(agent)
    db.commit()
