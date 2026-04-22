import redis.asyncio as aioredis
from app.config import settings
from typing import Any

# Module-level pool — created once, reused across the app lifetime.
_redis_pool: Any = None


async def get_redis() -> Any:
    global _redis_pool
    if _redis_pool is None:
        _redis_pool = aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
    return _redis_pool


async def close_redis() -> None:
    global _redis_pool
    if _redis_pool is not None:
        await _redis_pool.aclose()
        _redis_pool = None