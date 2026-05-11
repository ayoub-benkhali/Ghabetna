from pydantic_settings import BaseSettings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    AUTH_DATABASE_URL: str
    AUTH_DATABASE_URL_SYNC: str
    REDIS_URL: str = "redis://localhost:6379/0"
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: str
    MAIL_SERVER: str = "smtp.gmail.com"
    MAIL_PORT: int = 587
    FRONTEND_URL: str = "http://localhost:3000"
    FOREST_SERVICE_URL: str = "http://forest-service:8000"
    N8N_WEBHOOK_URL: str = "http://n8n:5678/webhook/security-event"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings() # type: ignore
logger.info(f"FRONTEND_URL: {settings.FRONTEND_URL}")