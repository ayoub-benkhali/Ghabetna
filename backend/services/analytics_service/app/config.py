from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Points to the SAME incident DB, read-only connection
    INCIDENT_SERVICE_URL: str = "http://incident-service:8000"
    ANALYTICS_DATABASE_URL: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    SECURITY_WEBHOOK_SECRET: str = "n8n_webhook_secret"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()  # type: ignore