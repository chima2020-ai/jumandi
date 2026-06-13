import random
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User, UserRole
from app.schemas.auth import (
    ForgotPassword,
    OtpVerify,
    ResetPassword,
    Token,
    UserRegister,
    UserResponse,
    UserUpdate,
)
from app.services.email_service import EmailServiceError, send_otp_email
from app.utils.auth import (
    create_access_token,
    get_current_user,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _generate_otp() -> str:
    return f"{random.randint(0, 9999):04d}"


def _generate_reset_token() -> str:
    return secrets.token_urlsafe(24)


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _is_expired(value: datetime | None) -> bool:
    if value is None:
        return True
    expires_at = value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return expires_at < _utc_now()


def _send_otp_to_user(user: User, db: Session) -> str:
    code = _generate_otp()
    user.otp_code = code
    user.otp_expires_at = _utc_now() + timedelta(minutes=10)
    db.commit()
    send_otp_email(to_email=user.email, to_name=user.name, code=code)
    return code


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(data: UserRegister, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    user = User(
        name=data.name,
        email=data.email,
        phone=data.phone,
        hashed_password=hash_password(data.password),
        role=data.role,
        is_verified=data.role == UserRole.DELIVERY,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    otp_message = None
    if data.role == UserRole.CUSTOMER:
        try:
            _send_otp_to_user(user, db)
            otp_message = "Verification code sent to your email"
        except Exception as exc:
            otp_message = f"Account created but email failed: {exc}"

    token = create_access_token(user.id, user.role)
    return Token(
        access_token=token,
        user=UserResponse.model_validate(user),
        message=otp_message,
    )


@router.post("/login", response_model=Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    token = create_access_token(user.id, user.role)
    return Token(access_token=token, user=UserResponse.model_validate(user))


@router.get("/me", response_model=UserResponse)
def get_me(user: User = Depends(get_current_user)):
    return user


@router.patch("/me", response_model=UserResponse)
def update_me(
    data: UserUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.name is not None:
        user.name = data.name
    if data.phone is not None:
        user.phone = data.phone
    db.commit()
    db.refresh(user)
    return user


@router.post("/otp/send")
def send_otp(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.is_verified:
        return {"message": "Account already verified"}

    try:
        _send_otp_to_user(user, db)
    except EmailServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc
    return {
        "message": "Verification code sent to your email",
    }


@router.post("/otp/verify", response_model=UserResponse)
def verify_otp(
    data: OtpVerify,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.is_verified:
        return user

    if not user.otp_code or not user.otp_expires_at:
        raise HTTPException(status_code=400, detail="No verification code found")

    if _is_expired(user.otp_expires_at):
        raise HTTPException(status_code=400, detail="Verification code expired")

    if data.code.strip() != user.otp_code:
        raise HTTPException(status_code=400, detail="Invalid verification code")

    user.is_verified = True
    user.otp_code = None
    user.otp_expires_at = None
    db.commit()
    db.refresh(user)
    return user


@router.post("/forgot-password")
def forgot_password(data: ForgotPassword, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        return {"message": "If that email exists, a reset code was sent"}

    token = _generate_reset_token()
    user.reset_token = token
    user.reset_token_expires_at = _utc_now() + timedelta(minutes=30)
    db.commit()

    return {
        "message": "If that email exists, a reset code was sent",
        "reset_token": token,
    }


@router.post("/reset-password")
def reset_password(data: ResetPassword, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not user.reset_token or not user.reset_token_expires_at:
        raise HTTPException(status_code=400, detail="Invalid reset request")

    if _is_expired(user.reset_token_expires_at):
        raise HTTPException(status_code=400, detail="Reset token expired")

    if data.token != user.reset_token:
        raise HTTPException(status_code=400, detail="Invalid reset token")

    user.hashed_password = hash_password(data.new_password)
    user.reset_token = None
    user.reset_token_expires_at = None
    db.commit()

    return {"message": "Password updated successfully"}
