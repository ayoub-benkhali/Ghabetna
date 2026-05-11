import redis.asyncio as aioredis
from fastapi import Depends,APIRouter,Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.config import settings
from app.database import get_db
from app.schemas.auth import LoginRequest,TokenResponse,RefreshRequest,ActivativateAccountRequest,AccessTokenResponse
from app.services import auth_service

router=APIRouter(prefix="/auth",tags=["Authentication"])

_redis_pool:aioredis.Redis|None=None

async def get_redis()-> aioredis.Redis:
    global _redis_pool
    if _redis_pool is None:
        _redis_pool=aioredis.from_url(settings.REDIS_URL,decode_responses=True)
    return _redis_pool

def _get_client_ip(request: Request) -> str:
    """Extracts real IP, respecting X-Forwarded-For from the API gateway."""
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return request.client.host if request.client else "0.0.0.0"

@router.post("/login",response_model=TokenResponse)
async def login(
    request: Request,
    data:LoginRequest,
    db:AsyncSession=Depends(get_db),
    redis:aioredis.Redis=Depends(get_redis)
):
    ip=_get_client_ip(request)
    access_token,refresh_token=await auth_service.login(data.email,data.password,ip,db,redis)
    return TokenResponse(access_token=access_token,refresh_token=refresh_token)

@router.post("/refresh",response_model=AccessTokenResponse)
async def refresh(
    data:RefreshRequest,
    db:AsyncSession=Depends(get_db),
    redis:aioredis.Redis=Depends(get_redis),
):
    access_token=await auth_service.refresh(data.refresh_token,db,redis)
    return AccessTokenResponse(access_token=access_token)

@router.post("/logout",status_code=204)
async def logout(
    data:RefreshRequest,
    redis:aioredis.Redis=Depends(get_redis)
):
    await auth_service.logout(data.refresh_token,redis)

@router.post("/activate",status_code=200)
async def activate(data:ActivativateAccountRequest,db:AsyncSession=Depends(get_db)):
    await auth_service.activate_account(data.token,data.password,db)
    return {"message":"Account activated successfully"}
