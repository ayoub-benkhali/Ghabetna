from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.routers.analytics_router import router as analytics_router
from app.routers.security_router import router as security_router
from app.database import engine, Base
from app.models import security  # ensures tables are registered


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Auto-create security tables on startup (no Alembic needed for new tables)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(title="Ghabetna Analytics Service", lifespan=lifespan)
app.include_router(analytics_router)
app.include_router(security_router)


@app.get("/health")
async def health():
    return {"status": "ok"}