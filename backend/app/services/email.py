import logging
from email.mime.text import MIMEText

import aiosmtplib

from app.core.config import settings

logger = logging.getLogger(__name__)

_SUBJECT = "OndaCerta — verifica o teu email"


def _build_message(to_email: str, code: str) -> MIMEText:
    body = (
        f"O teu código de verificação é:\n\n"
        f"    {code}\n\n"
        f"Expira em {settings.EMAIL_VERIFICATION_EXPIRE_MINUTES} minutos.\n\n"
        "Se não criaste uma conta na OndaCerta, ignora este email."
    )
    msg = MIMEText(body, "plain", "utf-8")
    msg["Subject"] = _SUBJECT
    msg["From"] = settings.EMAIL_FROM
    msg["To"] = to_email
    return msg


async def send_verification_email(to_email: str, code: str) -> None:
    if not settings.SMTP_HOST:
        logger.info("DEV — email verification code for %s: %s", to_email, code)
        return

    msg = _build_message(to_email, code)
    await aiosmtplib.send(
        msg,
        hostname=settings.SMTP_HOST,
        port=settings.SMTP_PORT,
        username=settings.SMTP_USER or None,
        password=settings.SMTP_PASSWORD or None,
        use_tls=settings.SMTP_TLS,
    )

