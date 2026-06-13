from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import Base, engine
from app.routers import auth, bookings, calls, chat, delivery, websocket


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title=settings.app_name,
    description="Gas delivery booking API — customers book gas, delivery agents fulfill orders with live map tracking.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.app_url,
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
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
