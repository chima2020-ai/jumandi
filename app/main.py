from contextlib import asynccontextmanager
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.routers import admin, auth, bookings, calls, chat, delivery, websocket
from app.services.bootstrap import admin_count, ensure_admin_user, ensure_database_enums

logger = logging.getLogger(__name__)

ADMIN_DIST_CANDIDATES = (
    Path(__file__).resolve().parent / "static" / "admin",
    Path(__file__).resolve().parent.parent / "admin_web" / "dist",
)


def _resolve_admin_dist() -> Path | None:
    for candidate in ADMIN_DIST_CANDIDATES:
        if candidate.is_dir() and (candidate / "index.html").is_file():
            return candidate
    return None


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_database_enums(engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        ensure_admin_user(db)
    except Exception as exc:
        logger.warning("Admin bootstrap skipped: %s", exc)
    finally:
        db.close()
    yield


app = FastAPI(
    title=settings.app_name,
    description="Gas delivery booking API — customers book gas, delivery agents fulfill orders with live map tracking.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(admin.router, prefix="/api")
app.include_router(bookings.router, prefix="/api")
app.include_router(delivery.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
app.include_router(calls.router, prefix="/api")
app.include_router(websocket.router)


@app.get("/")
def root():
    base = settings.app_url.rstrip("/")
    return {
        "app": settings.app_name,
        "message": "Gas delivery booking API",
        "url": base,
        "api": f"{base}/api",
        "docs": f"{base}/docs",
        "admin": f"{base}/admin",
        "websocket": base.replace("https://", "wss://").replace("http://", "ws://"),
    }


def _mount_admin_ui() -> None:
    admin_dist = _resolve_admin_dist()
    if admin_dist is None:
        logger.warning(
            "Admin UI not found — checked %s",
            ", ".join(str(p) for p in ADMIN_DIST_CANDIDATES),
        )

        @app.get("/admin")
        @app.get("/admin/{path:path}")
        def admin_ui_missing(path: str = ""):
            base = settings.app_url.rstrip("/")
            return {
                "message": "Admin UI files missing on server.",
                "admin_api": f"{base}/api/admin/setup/status",
                "hint": "Redeploy the latest commit from GitHub.",
            }

        return

    app.mount(
        "/admin",
        StaticFiles(directory=str(admin_dist), html=True),
        name="admin-ui",
    )
    logger.info("Admin UI mounted at /admin from %s", admin_dist)


_mount_admin_ui()
