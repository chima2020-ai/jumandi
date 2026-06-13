import logging
import re

from sqlalchemy import text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.config import settings
from app.models.user import User, UserRole
from app.utils.auth import hash_password

logger = logging.getLogger(__name__)

# Accidental QA accounts created while verifying production setup.
_TEST_ADMIN_EMAILS = frozenset(
    {
        "testadmin555@jumandi.com",
        "testadmin777@jumandi.com",
        "testadmin888@jumandi.com",
        "testadmin999@jumandi.com",
    }
)

_ENUM_NAME_RE = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_]*$")


def _postgres_role_enum_names(conn) -> list[str]:
    """Find PostgreSQL enum types used for user roles."""
    names: list[str] = []

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
    if row:
        names.append(row[0])

    rows = conn.execute(
        text(
            """
            SELECT DISTINCT t.typname
            FROM pg_type t
            JOIN pg_enum e ON e.enumtypid = t.oid
            WHERE e.enumlabel IN ('customer', 'delivery')
            """
        )
    ).fetchall()
    for (enum_name,) in rows:
        if enum_name not in names:
            names.append(enum_name)

    return names


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


def _add_enum_value(conn, enum_name: str, value: str) -> None:
    if not _ENUM_NAME_RE.match(enum_name):
        raise ValueError(f"Unsafe enum type name: {enum_name}")

    quoted = f'"{enum_name}"'
    if _enum_has_value(conn, enum_name, value):
        return

    for sql in (
        f"ALTER TYPE {quoted} ADD VALUE IF NOT EXISTS '{value}'",
        f"ALTER TYPE {quoted} ADD VALUE '{value}'",
    ):
        try:
            conn.execute(text(sql))
            logger.info("Added %s value to enum %s", value, enum_name)
            return
        except Exception as exc:
            if "already exists" in str(exc).lower():
                return
            logger.warning("Enum alter attempt failed (%s): %s", sql, exc)

    if not _enum_has_value(conn, enum_name, value):
        raise RuntimeError(f"Could not add '{value}' to enum {enum_name}")


def migrate_user_role_to_varchar(engine: Engine) -> None:
    """Store roles as lowercase strings — avoids PostgreSQL enum name/value mismatches."""
    if engine.dialect.name != "postgresql":
        return

    try:
        with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
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
            if not row:
                return

            conn.execute(
                text(
                    """
                    ALTER TABLE users
                    ALTER COLUMN role TYPE VARCHAR(20)
                    USING (
                        CASE lower(role::text)
                            WHEN 'customer' THEN 'customer'
                            WHEN 'delivery' THEN 'delivery'
                            WHEN 'admin' THEN 'admin'
                            ELSE lower(role::text)
                        END
                    )
                    """
                )
            )
            logger.info("Migrated users.role from PostgreSQL enum to VARCHAR")
    except Exception as exc:
        logger.exception("Could not migrate users.role column: %s", exc)


def ensure_database_enums(engine: Engine) -> None:
    migrate_user_role_to_varchar(engine)

    if engine.dialect.name != "postgresql":
        return

    try:
        with engine.connect().execution_options(isolation_level="AUTOCOMMIT") as conn:
            enum_names = _postgres_role_enum_names(conn)
            for enum_name in enum_names:
                for value in ("customer", "delivery", "admin"):
                    try:
                        _add_enum_value(conn, enum_name, value)
                    except Exception:
                        pass
    except Exception as exc:
        logger.warning("Legacy enum extension skipped: %s", exc)


def cleanup_test_admins(db: Session) -> None:
    """Remove one-off test admins so real first-time setup still works."""
    try:
        admins = db.query(User).filter(User.role == UserRole.ADMIN).all()
    except Exception:
        db.rollback()
        return

    if len(admins) != 1:
        return

    only = admins[0]
    if only.email not in _TEST_ADMIN_EMAILS:
        return

    db.delete(only)
    db.commit()
    logger.info("Removed test admin account %s", only.email)


def admin_count(db: Session) -> int:
    try:
        return db.query(User).filter(User.role == UserRole.ADMIN).count()
    except Exception:
        db.rollback()
        result = db.execute(
            text("SELECT COUNT(*) FROM users WHERE lower(role::text) = 'admin'")
        )
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
