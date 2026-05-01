from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers.auth_proxy import router as auth_router
from app.routers.forest_proxy import router as forests_router
from app.routers.roles_proxy import router as roles_router
from app.routers.users_proxy import router as users_router
from app.routers.parcelle_proxy import router as parcelles_router,flat_router as parcelles_flat_router
from app.routers.service_proxy import router as services_router
from app.routers.assignment_proxy import router as assignments_router
from app.routers.incident_proxy import router as incidents_router
from app.routers.analytics_proxy import router as analytics_router
import os
from contextlib import asynccontextmanager
from fastapi.staticfiles import StaticFiles

UPLOADS_DIR = os.getenv("UPLOAD_DIR", "/uploads")

os.makedirs(UPLOADS_DIR, exist_ok=True)

app=FastAPI(title="Ghabetna - API Gateway",version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads",StaticFiles(directory=UPLOADS_DIR),name="uploads")

app.include_router(auth_router)
app.include_router(forests_router)
app.include_router(parcelles_router)
app.include_router(parcelles_flat_router)
app.include_router(roles_router)
app.include_router(users_router)
app.include_router(services_router)
app.include_router(assignments_router)
app.include_router(incidents_router)
app.include_router(analytics_router)

@app.get("/health")
async def health():
    return {"status":"ok","service":"api-gateway"}
