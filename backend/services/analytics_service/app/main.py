from fastapi import FastAPI
from app.routers.analytics_router import router

app = FastAPI(title="Ghabetna Analytics Service")
app.include_router(router)

@app.get("/health")
async def health():
    return {"status": "ok"}