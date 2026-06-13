from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session, joinedload

from app.database import engine, get_db
from app.models.booking import Booking, BookingStatus
from app.models.call import CallLog
from app.models.message import Message
from app.models.user import User, UserRole
from app.schemas.admin import (
    ActivityFeedResponse,
    ActivityItem,
    AdminCreate,
    AdminOverview,
    AdminSetupStatus,
    BookingListResponse,
    CustomerListResponse,
    DeliveryAgentCreate,
    DeliveryAgentListResponse,
    DeliveryAgentUpdate,
)
from app.schemas.auth import UserResponse
from app.schemas.booking import BookingResponse
from app.services.bootstrap import admin_count, ensure_database_enums
from app.utils.auth import hash_password, require_role

router = APIRouter(prefix="/admin", tags=["Admin"])


def _admin_count(db: Session) -> int:
    return admin_count(db)


@router.get("/setup/status", response_model=AdminSetupStatus)
def admin_setup_status(db: Session = Depends(get_db)):
    count = _admin_count(db)
    return AdminSetupStatus(needs_setup=count == 0, admin_count=count)


@router.post("/setup", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def setup_first_admin(data: AdminCreate, db: Session = Depends(get_db)):
    """Create the first admin account when none exist yet."""
    ensure_database_enums(engine)

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
    try:
        db.add(admin)
        db.commit()
        db.refresh(admin)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )
    except SQLAlchemyError as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not create admin account: {exc.orig if exc.orig else exc}",
        ) from exc

    return admin


@router.get("/overview", response_model=AdminOverview)
def admin_overview(
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    """App-wide stats for the admin dashboard."""
    customers = db.query(User).filter(User.role == UserRole.CUSTOMER).count()
    drivers = db.query(User).filter(User.role == UserRole.DELIVERY).count()
    drivers_online = (
        db.query(User)
        .filter(User.role == UserRole.DELIVERY, User.is_available.is_(True))
        .count()
    )
    admins = _admin_count(db)

    bookings_total = db.query(Booking).count()
    bookings_pending = (
        db.query(Booking).filter(Booking.status == BookingStatus.PENDING).count()
    )
    bookings_active = (
        db.query(Booking)
        .filter(
            Booking.status.in_([BookingStatus.ACCEPTED, BookingStatus.IN_TRANSIT])
        )
        .count()
    )
    bookings_delivered = (
        db.query(Booking).filter(Booking.status == BookingStatus.DELIVERED).count()
    )
    bookings_cancelled = (
        db.query(Booking).filter(Booking.status == BookingStatus.CANCELLED).count()
    )
    gas_kg_delivered = (
        db.query(func.coalesce(func.sum(Booking.gas_kg), 0))
        .filter(Booking.status == BookingStatus.DELIVERED)
        .scalar()
    )

    return AdminOverview(
        customers=customers,
        drivers=drivers,
        drivers_online=drivers_online,
        admins=admins,
        bookings_total=bookings_total,
        bookings_pending=bookings_pending,
        bookings_active=bookings_active,
        bookings_delivered=bookings_delivered,
        bookings_cancelled=bookings_cancelled,
        gas_kg_delivered=float(gas_kg_delivered or 0),
        messages_total=db.query(Message).count(),
        calls_total=db.query(CallLog).count(),
    )


@router.get("/bookings", response_model=BookingListResponse)
def list_all_bookings(
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
    status_filter: BookingStatus | None = Query(default=None, alias="status"),
    limit: int = Query(default=100, ge=1, le=500),
):
    """All orders across the platform."""
    query = db.query(Booking).options(
        joinedload(Booking.customer),
        joinedload(Booking.delivery_agent),
    )
    if status_filter is not None:
        query = query.filter(Booking.status == status_filter)

    bookings = query.order_by(Booking.created_at.desc()).limit(limit).all()
    total_query = db.query(Booking)
    if status_filter is not None:
        total_query = total_query.filter(Booking.status == status_filter)

    return BookingListResponse(
        bookings=[BookingResponse.model_validate(b) for b in bookings],
        total=total_query.count(),
    )


@router.get("/bookings/{booking_id}", response_model=BookingResponse)
def get_booking_admin(
    booking_id: int,
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    booking = (
        db.query(Booking)
        .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
        .filter(Booking.id == booking_id)
        .first()
    )
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@router.get("/customers", response_model=CustomerListResponse)
def list_customers(
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
):
    customers = (
        db.query(User)
        .filter(User.role == UserRole.CUSTOMER)
        .order_by(User.created_at.desc())
        .all()
    )
    return CustomerListResponse(
        customers=[UserResponse.model_validate(c) for c in customers],
        total=len(customers),
    )


@router.get("/activity", response_model=ActivityFeedResponse)
def recent_activity(
    user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db),
    limit: int = Query(default=30, ge=1, le=100),
):
    """Recent orders and sign-ups for the live feed."""
    items: list[ActivityItem] = []

    bookings = (
        db.query(Booking)
        .options(joinedload(Booking.customer), joinedload(Booking.delivery_agent))
        .order_by(Booking.created_at.desc())
        .limit(limit)
        .all()
    )
    for booking in bookings:
        customer_name = booking.customer.name if booking.customer else "Customer"
        status_label = booking.status.value.replace("_", " ")
        driver = (
            f" — driver {booking.delivery_agent.name}"
            if booking.delivery_agent
            else ""
        )
        items.append(
            ActivityItem(
                type="booking",
                message=f"Order #{booking.id}: {customer_name} booked {booking.gas_kg}kg ({status_label}){driver}",
                created_at=booking.created_at,
                booking_id=booking.id,
            )
        )

    new_customers = (
        db.query(User)
        .filter(User.role == UserRole.CUSTOMER)
        .order_by(User.created_at.desc())
        .limit(10)
        .all()
    )
    for customer in new_customers:
        items.append(
            ActivityItem(
                type="customer",
                message=f"New customer signed up: {customer.name} ({customer.email})",
                created_at=customer.created_at,
            )
        )

    items.sort(key=lambda item: item.created_at, reverse=True)
    return ActivityFeedResponse(items=items[:limit])


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
    ensure_database_enums(engine)

    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        if existing.role == UserRole.DELIVERY:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A driver with this email already exists",
            )
        if existing.role == UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot convert an admin account into a driver",
            )
        existing.name = data.name
        existing.phone = data.phone
        existing.hashed_password = hash_password(data.password)
        existing.role = UserRole.DELIVERY
        existing.is_verified = True
        existing.is_available = True
        try:
            db.commit()
            db.refresh(existing)
        except SQLAlchemyError as exc:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Could not update account to driver: {exc.orig if exc.orig else exc}",
            ) from exc
        return existing

    agent = User(
        name=data.name,
        email=data.email,
        phone=data.phone,
        hashed_password=hash_password(data.password),
        role=UserRole.DELIVERY,
        is_verified=True,
        is_available=True,
    )
    try:
        db.add(agent)
        db.commit()
        db.refresh(agent)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )
    except SQLAlchemyError as exc:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not create driver: {exc.orig if exc.orig else exc}",
        ) from exc
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
