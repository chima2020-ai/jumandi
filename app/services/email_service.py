import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import httpx

from app.config import settings


class EmailServiceError(Exception):
    pass


def _html_body(to_name: str, code: str) -> str:
    return f"""
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
    """


def _send_via_smtp(*, to_email: str, to_name: str, code: str) -> None:
    """Use Brevo SMTP relay (key starts with xsmtpsib-)."""
    if not settings.brevo_api_key:
        raise EmailServiceError("Brevo SMTP key is not configured")

    message = MIMEMultipart("alternative")
    message["Subject"] = "Your Jumandi verification code"
    message["From"] = f"{settings.brevo_sender_name} <{settings.brevo_sender_email}>"
    message["To"] = to_email
    message.attach(MIMEText(_html_body(to_name, code), "html"))

    try:
        with smtplib.SMTP(settings.brevo_smtp_host, settings.brevo_smtp_port, timeout=30) as server:
            server.starttls()
            server.login(settings.smtp_login, settings.brevo_api_key)
            server.sendmail(settings.brevo_sender_email, [to_email], message.as_string())
    except smtplib.SMTPException as exc:
        raise EmailServiceError(f"Failed to send email via SMTP: {exc}") from exc


def _send_via_api(*, to_email: str, to_name: str, code: str) -> None:
    """Use Brevo REST API (key starts with xkeysib-)."""
    if not settings.brevo_api_key:
        raise EmailServiceError("Brevo API key is not configured")

    payload = {
        "sender": {
            "name": settings.brevo_sender_name,
            "email": settings.brevo_sender_email,
        },
        "to": [{"email": to_email, "name": to_name}],
        "subject": "Your Jumandi verification code",
        "htmlContent": _html_body(to_name, code),
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
        raise EmailServiceError(f"Failed to send email via API: {exc}") from exc


def send_otp_email(*, to_email: str, to_name: str, code: str) -> None:
    """Send OTP using Brevo SMTP or REST API depending on key type."""
    key = settings.brevo_api_key.strip()
    if key.startswith("xsmtpsib-"):
        _send_via_smtp(to_email=to_email, to_name=to_name, code=code)
    elif key.startswith("xkeysib-"):
        _send_via_api(to_email=to_email, to_name=to_name, code=code)
    else:
        raise EmailServiceError(
            "Invalid Brevo key. Use an SMTP key (xsmtpsib-) or API key (xkeysib-)."
        )
