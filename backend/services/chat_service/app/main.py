from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import chat_router
from app.services.rag_service import rag_service

@asynccontextmanager
async def lifespan(app: FastAPI):
    rag_service.initialize()
    yield

app = FastAPI(
    title="Ghabetna - Chat Service",
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

app.include_router(chat_router.router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "chat-service"}