import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.firebase import init_firebase
from app.scheduler.setup import create_scheduler
from app.api import auth, beaches, reports, flags, occupancy, weather, tides, water_quality, transport, users, favourites, notifications, privacy, map

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

app.include_router(auth.router,           prefix="/api/v1")
app.include_router(beaches.router,        prefix="/api/v1")
app.include_router(reports.router,        prefix="/api/v1")
app.include_router(flags.router,          prefix="/api/v1")
app.include_router(occupancy.router,      prefix="/api/v1")
app.include_router(weather.router,        prefix="/api/v1")
app.include_router(tides.router,          prefix="/api/v1")
app.include_router(water_quality.router,  prefix="/api/v1")
app.include_router(transport.router,      prefix="/api/v1")
app.include_router(users.router,          prefix="/api/v1")
app.include_router(favourites.router,     prefix="/api/v1")
app.include_router(notifications.router,  prefix="/api/v1")
app.include_router(privacy.router,        prefix="/api/v1")
app.include_router(map.router,            prefix="/api/v1")


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
