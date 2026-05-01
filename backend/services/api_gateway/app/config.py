from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

env_path = Path(__file__).parent.parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=env_path,
        extra="allow"
    )

    AUTH_SERVICE_URL:str="http://auth-service:8000"
    FOREST_SERVICE_URL:str="http://forest-service:8000"
    INCIDENT_SERVICE_URL:str="http://incident-service:8000"
    ANALYTICS_SERVICE_URL: str = "http://analytics-service:8000"
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"

print(env_path.exists())
settings = Settings() # type: ignore
