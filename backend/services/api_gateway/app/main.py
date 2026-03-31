from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers.auth_proxy import router as auth_router
from app.routers.forest_proxy import router as forests_router
from app.routers.roles_proxy import router as roles_router
from app.routers.users_proxy import router as users_router
from app.routers.parcelle_proxy import router as parcelles_router
from app.routers.service_proxy import router as services_router

app=FastAPI(title="Ghabetna - API Gateway",version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(forests_router)
app.include_router(parcelles_router)
app.include_router(roles_router)
app.include_router(users_router)
app.include_router(services_router)

@app.get("/health")
async def health():
    return {"status":"ok","service":"api-gateway"}
