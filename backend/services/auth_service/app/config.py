from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

env_path = Path(__file__).parent.parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=env_path,
        extra="allow"
    )

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

settings = Settings()  # type: ignore
logger.info(f"the path variable exists: {env_path.exists()}")
logger.info(f"AUTH_DATABASE_URL: {settings.AUTH_DATABASE_URL}")
logger.info(f"FRONTEND_URL: {settings.FRONTEND_URL}")
