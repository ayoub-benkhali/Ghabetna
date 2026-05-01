from sqlalchemy.ext.asyncio import AsyncSession,create_async_engine,async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings
from typing import AsyncGenerator

engine=create_async_engine(settings.INCIDENT_DATABASE_URL,echo=False,pool_pre_ping=True)
AsyncSessionLocal=async_sessionmaker(engine,class_=AsyncSession,expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_db()->AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
