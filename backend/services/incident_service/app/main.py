from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
import os
from app.database import engine, Base
from app.models.incident import Incident
from app.routers.incident_router import router as incident_router
from app.routers.analytics_router import router as analytics_router
from app.config import settings
from app.workers.geo_enrichment import run_worker
from app.redis_client import close_redis
import asyncio

@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ──────────────────────────────────────────────────────────────
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)

    stop_event = asyncio.Event()
    worker_task = asyncio.create_task(run_worker(stop_event))  

    yield

    # ── Shutdown ─────────────────────────────────────────────────────────────
    stop_event.set()           # signal the worker to exit
    await worker_task          # wait for clean exit
    await close_redis()  

app = FastAPI(title="Ghabetna - Incident Service", version="1.0.0", lifespan=lifespan)

os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

app.include_router(incident_router)
app.include_router(analytics_router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "incident-service"}