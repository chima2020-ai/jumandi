from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Jumandi"
    app_url: str = "https://jumandi.onrender.com"
    secret_key: str = "change-this-secret-key-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days
    database_url: str = "sqlite:///./jumandi.db"
    brevo_api_key: str = ""
    brevo_sender_email: str = "chiapps20@gmail.com"
    brevo_sender_name: str = "jumandi"
    brevo_smtp_login: str = ""
    brevo_smtp_host: str = "smtp-relay.brevo.com"
    brevo_smtp_port: int = 587
    cors_origins: str = ""
    admin_email: str = ""
    admin_password: str = ""
    admin_name: str = "Jumandi Admin"
    admin_phone: str = "0000000000"

    @property
    def smtp_login(self) -> str:
        return self.brevo_smtp_login or self.brevo_sender_email

    @property
    def cors_origin_list(self) -> list[str]:
        origins = [
            self.app_url.rstrip("/"),
            "http://localhost:8000",
            "http://127.0.0.1:8000",
            "http://10.0.2.2:8000",
        ]
        if self.cors_origins.strip():
            origins.extend(o.strip() for o in self.cors_origins.split(",") if o.strip())
        return list(dict.fromkeys(origins))

    model_config = SettingsConfigDict(
        env_file=".env" if Path(".env").exists() else None,
        env_file_encoding="utf-8",
    )

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: str) -> str:
        """Render provides postgres:// — SQLAlchemy needs postgresql+psycopg2://"""
        if value.startswith("postgres://"):
            value = value.replace("postgres://", "postgresql://", 1)
        if value.startswith("postgresql://") and "+psycopg" not in value:
            value = value.replace("postgresql://", "postgresql+psycopg2://", 1)
        return value


settings = Settings()
