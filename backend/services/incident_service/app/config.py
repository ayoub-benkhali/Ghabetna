from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    INCIDENT_DATABASE_URL: str
    INCIDENT_DATABASE_URL_SYNC: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    UPLOAD_DIR: str = "/uploads"
    MAX_IMAGE_SIZE_MB: int = 10
    REDIS_URL: str = "redis://localhost:6379/0"
    FOREST_SERVICE_URL: str = "http://forest-service:8000"

    class Config:
        env_file = ".env"

settings = Settings() # type: ignore #type