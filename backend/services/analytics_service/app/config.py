from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Points to the SAME incident DB, read-only connection
    INCIDENT_DATABASE_URL: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()  # type: ignore