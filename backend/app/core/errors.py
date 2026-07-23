from typing import Optional

from fastapi import HTTPException

from app.core.i18n import t
from app.core.language import DEFAULT_LANGUAGE


def api_error(
    status_code: int,
    code: str,
    lang: str = DEFAULT_LANGUAGE,
    *,
    extra: Optional[dict] = None,
    **params,
) -> HTTPException:
    """Build an HTTPException whose detail is always {"code", "message", ...}.

    `message` is a rendered convenience string, never the source of truth —
    clients must branch on `code` and resolve their own display text.
    `params` are used only to render `message`; `extra` adds raw fields to
    the response body (e.g. `suspended_until`) without going through t().
    """
    detail = {"code": code, "message": t(code, lang, **params)}
    if extra:
        detail.update(extra)
    return HTTPException(status_code=status_code, detail=detail)
