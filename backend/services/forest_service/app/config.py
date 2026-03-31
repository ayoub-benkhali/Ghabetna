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
    FOREST_DATABASE_URL: str           
    FOREST_DATABASE_URL_SYNC: str     
    REDIS_URL: str = "redis://localhost:6379/1"
    
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"

print(env_path.exists())
settings = Settings()
print(settings.FOREST_DATABASE_URL)
