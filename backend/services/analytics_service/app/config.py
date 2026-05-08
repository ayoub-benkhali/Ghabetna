from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Points to the SAME incident DB, read-only connection
    INCIDENT_SERVICE_URL: str = "http://incident-service:8000"
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()  # type: ignore