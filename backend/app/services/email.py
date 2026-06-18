import logging
from email.mime.text import MIMEText

import aiosmtplib

from app.core.config import settings

logger = logging.getLogger(__name__)


def _make_message(to_email: str, subject: str, body: str) -> MIMEText:
    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = subject
    msg["From"] = settings.EMAIL_FROM
    msg["To"] = to_email
    return msg


async def _send_message(msg: MIMEText) -> None:
    await aiosmtplib.send(
        msg,
        hostname=settings.SMTP_HOST,
        port=settings.SMTP_PORT,
        username=settings.SMTP_USER or None,
        password=settings.SMTP_PASSWORD or None,
        use_tls=settings.SMTP_TLS,
    )


async def send_verification_email(to_email: str, code: str) -> None:
    if not settings.SMTP_HOST:
        logger.info("DEV — email verification code for %s: %s", to_email, code)
        return

    body = (
        f"O teu código de verificação é:\n\n"
        f"    {code}\n\n"
        f"Expira em {settings.EMAIL_VERIFICATION_EXPIRE_MINUTES} minutos.\n\n"
        "Se não criaste uma conta na OndaCerta, ignora este email."
    )
    await _send_message(_make_message(to_email, "OndaCerta — verifica o teu email", body))


async def send_password_reset_email(to_email: str, code: str) -> None:
    if not settings.SMTP_HOST:
        logger.info("DEV — password reset code for %s: %s", to_email, code)
        return

    body = (
        f"O teu código de recuperação de password é:\n\n"
        f"    {code}\n\n"
        f"Expira em {settings.EMAIL_VERIFICATION_EXPIRE_MINUTES} minutos.\n\n"
        "Se não pediste a recuperação de password na OndaCerta, ignora este email."
    )
    await _send_message(_make_message(to_email, "OndaCerta — recuperação de password", body))
