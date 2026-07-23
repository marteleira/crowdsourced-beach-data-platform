import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exception_handlers import http_exception_handler as default_http_exception_handler
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.config import settings
from app.core.firebase import init_firebase
from app.core.i18n import t
from app.core.language import resolve_language
from app.schemas.errors import CodedValueError
from app.scheduler.setup import create_scheduler
from app.api import auth, beaches, reports, flags, occupancy, weather, tides, water_quality, transport, users, favourites, notifications, privacy, map as map_router

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    scheduler = create_scheduler()
    scheduler.start()
    yield
    scheduler.shutdown(wait=False)


app = FastAPI(
    title="Arrábida Beach API",
    version="0.1.0",
    description="Backend for the Arrábida beach information and community app",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,               prefix="/api/v1")
app.include_router(beaches.router,            prefix="/api/v1")
app.include_router(reports.router,            prefix="/api/v1")
app.include_router(flags.router,              prefix="/api/v1")
app.include_router(occupancy.router,          prefix="/api/v1")
app.include_router(occupancy.location_router, prefix="/api/v1")
app.include_router(weather.router,            prefix="/api/v1")
app.include_router(tides.router,              prefix="/api/v1")
app.include_router(water_quality.router,      prefix="/api/v1")
app.include_router(transport.router,          prefix="/api/v1")
app.include_router(users.router,              prefix="/api/v1")
app.include_router(favourites.router,         prefix="/api/v1")
app.include_router(notifications.router,      prefix="/api/v1")
app.include_router(privacy.router,            prefix="/api/v1")
app.include_router(map_router.router,         prefix="/api/v1")


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Every Pydantic validation error becomes {"errors": [{"code","field","message"}]} —
    distinct from the single-error {"code","message"} shape used by api_error(), so the
    client can always tell "malformed input" (422, possibly multiple problems) apart from
    "a single business rule was violated" (any other 4xx) by response shape alone."""
    lang = resolve_language(request.headers.get("accept-language"))
    errors = []
    for err in exc.errors():
        raw = err.get("ctx", {}).get("error")
        if isinstance(raw, CodedValueError):
            code, message = raw.code, t(raw.code, lang, **raw.params)
        else:
            code, message = err.get("type", "validation_error"), err.get("msg", "")
        field = ".".join(str(p) for p in err.get("loc", ())[1:])
        errors.append({"code": code, "field": field, "message": message})
    return JSONResponse(status_code=422, content={"errors": errors})


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Normalise framework-level HTTPExceptions (404 route not found, 405, ...) whose
    detail is a plain string into the same {"code","message"} shape api_error() uses,
    so literally every non-2xx response follows one of exactly two documented shapes."""
    if isinstance(exc.detail, dict):
        return await default_http_exception_handler(request, exc)
    normalised = StarletteHTTPException(
        status_code=exc.status_code,
        detail={"code": "http_error", "message": str(exc.detail)},
        headers=exc.headers,
    )
    return await default_http_exception_handler(request, normalised)


_static_dir = os.path.join(os.path.dirname(__file__), "..", "static")
os.makedirs(_static_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=_static_dir), name="static")


@app.get("/", include_in_schema=False)
async def landing_page():
    return FileResponse(os.path.join(_static_dir, "site", "index.html"))


@app.get("/terms", include_in_schema=False)
async def terms_page():
    return FileResponse(os.path.join(_static_dir, "site", "terms.html"))


@app.get("/privacy", include_in_schema=False)
async def privacy_page():
    return FileResponse(os.path.join(_static_dir, "site", "privacy.html"))


@app.get("/health")
async def health():
    return {"status": "ok"}
