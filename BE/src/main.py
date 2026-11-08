"""
src/main.py – Application entry point.

To add a new module, import its router and include it below.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from apps.auth.controllers.auth_controller import router as auth_router
from apps.company.services.bootstrap import bootstrap_admin
from apps.user.controllers.user_controller import router as user_router
from core.config import settings
from core.database import AsyncSessionLocal


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with AsyncSessionLocal() as db:
        await bootstrap_admin(db)
    yield


app = FastAPI(
    title="Transport Management API",
    version="0.1.0",
    description="Backend for the Gujarati transport management mobile app",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# The mobile app is not a browser, so CORS only matters for local Swagger/dev tools.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.is_development else [],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────────
app.include_router(auth_router, prefix="/api/v1")
app.include_router(user_router, prefix="/api/v1")


@app.get("/health", tags=["Health"])
async def health() -> dict:
    return {"status": "ok"}
