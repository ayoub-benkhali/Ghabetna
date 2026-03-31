from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine,Base
from app.models.role import Role
from app.models.user import User
from app.routers import auth,users_router,roles_router,service_router

@asynccontextmanager
async def lifespan(app:FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app=FastAPI(
    title="Ghabetna - Auth Service",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(auth.router)
app.include_router(users_router.router)
app.include_router(roles_router.router)
app.include_router(service_router.router)

@app.get("/health")
async def health():
    return {"status":"ok","service":"auth-service"}
