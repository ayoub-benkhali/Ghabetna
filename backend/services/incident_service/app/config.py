from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    INCIDENT_DATABASE_URL: str
    INCIDENT_DATABASE_URL_SYNC: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    UPLOAD_DIR: str = "/app/uploads"
    MAX_IMAGE_SIZE_MB: int = 10

    class Config:
        env_file = ".env"

settings = Settings() # type: ignore #type