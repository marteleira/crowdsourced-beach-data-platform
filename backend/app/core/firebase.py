"""
Firebase Admin SDK initialization

Set FIREBASE_CREDENTIALS_PATH in .env to the path of the serviceAccountKey.json
downloaded from Firebase Console -> Project Settings -> Service Accounts.

If the variable is not set (e.g. local dev without credentials), the firebase is not
initialized and push notifications fall back to stub logging.
"""
import logging

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_initialized = False


def init_firebase() -> None:
    global _firebase_initialized
    if _firebase_initialized:
        return
    if not settings.FIREBASE_CREDENTIALS_PATH:
        logger.warning("FIREBASE_CREDENTIALS_PATH not set -> push notifications will be stubbed")
        return
    try:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized")
    except Exception as exc:
        logger.error("Failed to initialize Firebase: %s", exc)


def is_firebase_ready() -> bool:
    return _firebase_initialized
