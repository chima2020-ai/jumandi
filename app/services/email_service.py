import httpx

from app.config import settings


class EmailServiceError(Exception):
    pass


def send_otp_email(*, to_email: str, to_name: str, code: str) -> None:
    """Send a 4-digit OTP via Brevo transactional email."""
    if not settings.brevo_api_key:
        raise EmailServiceError("Brevo API key is not configured")

    payload = {
        "sender": {
            "name": settings.brevo_sender_name,
            "email": settings.brevo_sender_email,
        },
        "to": [{"email": to_email, "name": to_name}],
        "subject": "Your Jumandi verification code",
        "htmlContent": f"""
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
          <h2 style="color: #f5a623;">Jumandi</h2>
          <p>Hello {to_name},</p>
          <p>Your verification code is:</p>
          <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #111;">
            {code}
          </p>
          <p>This code expires in 10 minutes.</p>
          <p>If you did not request this, you can ignore this email.</p>
        </div>
        """,
    }

    try:
        response = httpx.post(
            "https://api.brevo.com/v3/smtp/email",
            headers={
                "api-key": settings.brevo_api_key,
                "content-type": "application/json",
                "accept": "application/json",
            },
            json=payload,
            timeout=30.0,
        )
        response.raise_for_status()
    except httpx.HTTPError as exc:
        raise EmailServiceError(f"Failed to send email: {exc}") from exc
