from pydantic_settings import BaseSettings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    GROQ_API_KEY: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    CHROMA_PERSIST_DIR: str = "/app/chroma_db"
    CHAT_SERVICE_PORT: int = 8000
    CHAT_DATABASE_URL: str

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings() # type: ignore
logger.info("Chat service config loaded")