from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.database import engine,Base
from app.models.forest import Forest
from app.routers.forest_router import router as forest_router, flat_router as forest_flat_router
from app.routers.parcelle_router import router as parcelle_router, flat_router as parcelle_flat_router

@asynccontextmanager
async def lifespan(app:FastAPI):
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
    yield

app=FastAPI(
    title="Ghabetna - Forest Service",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(forest_router)
app.include_router(parcelle_router)
app.include_router(parcelle_flat_router)
app.include_router(forest_flat_router)

@app.get("/health")
async def health():
    return {"status":"ok","service":"forest-service"}
