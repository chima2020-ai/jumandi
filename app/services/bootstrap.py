import logging

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.config import settings
from app.models.user import User, UserRole
from app.utils.auth import hash_password

logger = logging.getLogger(__name__)


def _postgres_role_enum_name(conn) -> str | None:
    row = conn.execute(
        text(
            """
            SELECT pg_type.typname
            FROM pg_attribute
            JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
            JOIN pg_type ON pg_type.oid = pg_attribute.atttypid
            WHERE pg_class.relname = 'users'
              AND pg_attribute.attname = 'role'
              AND pg_type.typtype = 'e'
            LIMIT 1
            """
        )
    ).fetchone()
    return row[0] if row else None


def _enum_has_value(conn, enum_name: str, value: str) -> bool:
    row = conn.execute(
        text(
            """
            SELECT 1
            FROM pg_enum e
            JOIN pg_type t ON e.enumtypid = t.oid
            WHERE t.typname = :enum_name AND e.enumlabel = :value
            LIMIT 1
            """
        ),
        {"enum_name": enum_name, "value": value},
    ).fetchone()
    return row is not None


def ensure_database_enums(engine) -> None:
    if engine.dialect.name != "postgresql":
        return

    try:
        with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
            enum_name = _postgres_role_enum_name(conn)
            if not enum_name:
                logger.warning("Could not find PostgreSQL enum type for users.role")
                return

            if _enum_has_value(conn, enum_name, "admin"):
                logger.info("Enum %s already includes admin", enum_name)
                return

            conn.execute(text(f"ALTER TYPE {enum_name} ADD VALUE IF NOT EXISTS 'admin'"))
            logger.info("Added admin value to enum %s", enum_name)
    except Exception as exc:
        logger.warning("Could not extend role enum with admin: %s", exc)


def admin_count(db: Session) -> int:
    try:
        return db.query(User).filter(User.role == UserRole.ADMIN).count()
    except Exception:
        db.rollback()
        result = db.execute(text("SELECT COUNT(*) FROM users WHERE role::text = 'admin'"))
        return int(result.scalar() or 0)


def ensure_admin_user(db: Session) -> None:
    if not settings.admin_email or not settings.admin_password:
        logger.info("ADMIN_EMAIL / ADMIN_PASSWORD not set — skipping default admin bootstrap")
        return

    try:
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
    except Exception as exc:
        db.rollback()
        logger.warning("Could not bootstrap admin user: %s", exc)
