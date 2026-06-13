from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, SessionLocal, engine
from app.routers import admin, auth, bookings, calls, chat, delivery, websocket
from app.services.bootstrap import ensure_admin_user, ensure_database_enums


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_database_enums(engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        ensure_admin_user(db)
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
        "websocket": base.replace("https://", "wss://").replace("http://", "ws://"),
    }
