import logging
from email.mime.text import MIMEText

import aiosmtplib

from app.core.config import settings
from app.core.i18n import t
from app.core.language import DEFAULT_LANGUAGE

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
        start_tls=settings.SMTP_TLS,
    )


async def send_verification_email(to_email: str, code: str, lang: str = DEFAULT_LANGUAGE) -> None:
    if not settings.SMTP_HOST:
        logger.info("DEV — email verification code for %s: %s", to_email, code)
        return

    subject = t("email_verify_subject", lang)
    body = t("email_verify_body", lang, code=code, minutes=settings.EMAIL_VERIFICATION_EXPIRE_MINUTES)
    await _send_message(_make_message(to_email, subject, body))


async def send_password_reset_email(to_email: str, code: str, lang: str = DEFAULT_LANGUAGE) -> None:
    if not settings.SMTP_HOST:
        logger.info("DEV — password reset code for %s: %s", to_email, code)
        return

    subject = t("email_reset_subject", lang)
    body = t("email_reset_body", lang, code=code, minutes=settings.EMAIL_VERIFICATION_EXPIRE_MINUTES)
    await _send_message(_make_message(to_email, subject, body))
