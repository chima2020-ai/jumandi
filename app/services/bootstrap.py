import logging

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.config import settings
from app.models.user import User, UserRole
from app.utils.auth import hash_password

logger = logging.getLogger(__name__)


def ensure_database_enums(engine) -> None:
    if engine.dialect.name != "postgresql":
        return

    try:
        with engine.begin() as conn:
            conn.execute(text("ALTER TYPE userrole ADD VALUE IF NOT EXISTS 'admin'"))
    except Exception as exc:
        logger.warning("Could not extend userrole enum: %s", exc)


def ensure_admin_user(db: Session) -> None:
    if not settings.admin_email or not settings.admin_password:
        logger.info("ADMIN_EMAIL / ADMIN_PASSWORD not set — skipping default admin bootstrap")
        return

    existing = db.query(User).filter(User.email == settings.admin_email).first()
    if existing:
        if existing.role != UserRole.ADMIN:
            existing.role = UserRole.ADMIN
            existing.is_verified = True
            db.commit()
        return

    admin = User(
        name=settings.admin_name,
        email=settings.admin_email,
        phone=settings.admin_phone,
        hashed_password=hash_password(settings.admin_password),
        role=UserRole.ADMIN,
        is_verified=True,
        is_available=True,
    )
    db.add(admin)
    db.commit()
    logger.info("Default admin account created for %s", settings.admin_email)
