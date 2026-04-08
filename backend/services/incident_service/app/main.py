from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
import os
from app.database import engine, Base
from app.models.incident import Incident
from app.routers.incident_router import router as incident_router
from app.config import settings

@asynccontextmanager
async def lifespan(app:FastAPI):
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(title="Ghabetna - Incident Service", version="1.0.0", lifespan=lifespan)

os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

app.include_router(incident_router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "incident-service"}