from datetime import datetime,timedelta,timezone
import redis.asyncio as aioredis
from fastapi import HTTPException,status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.config import settings
from app.models.user import User
from app.utils.jwt import decode_token,create_access_token,create_refresh_token
from app.utils.password import verify_password,hash_password
from app.models.supervisor_forest import supervisor_forest
from app.services.assignment_service import get_supervisor_forest_ids
import asyncio
from app.utils.security_events import emit_security_event

REFRESH_TOKEN_PREFIX="refresh:"
BLACKLIST_PREFIX="blacklist:"

FAILED_LOGIN_PREFIX = "failed_login:"
FAILED_LOGIN_TTL_SECONDS = 3600 


async def login(
    email: str,
    password: str,
    ip: str,           # NEW
    db: AsyncSession,
    redis: aioredis.Redis,
):
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    failed_attempts = await _get_failed_attempts(redis, ip)
    role_name = user.role.name if (user and user.role) else "unknown"

    # ── Auth checks ──────────────────────────────────────────────────────────
    if not user:
        new_count = await _increment_failed(redis, ip)
        asyncio.create_task(emit_security_event(
            event="login_failed",
            email=email,
            role="unknown",
            ip=ip,
            failed_attempts=new_count,
        ))
        raise HTTPException(status_code=401, detail="Invalid Email")

    if not user.is_active or not user.hashed_password:
        asyncio.create_task(emit_security_event(
            event="login_failed_inactive",
            email=email,
            role=role_name,
            ip=ip,
            failed_attempts=failed_attempts,
        ))
        raise HTTPException(status_code=401, detail="Account not activated")

    if not verify_password(password, user.hashed_password):
        new_count = await _increment_failed(redis, ip)
        asyncio.create_task(emit_security_event(
            event="login_failed",
            email=email,
            role=role_name,
            ip=ip,
            failed_attempts=new_count,
        ))
        raise HTTPException(status_code=401, detail="Invalid Password")

    # ── Success ──────────────────────────────────────────────────────────────
    await _reset_failed(redis, ip)

    permissions = user.role.permissions if user.role else []
    forest_ids = await get_supervisor_forest_ids(user.id, db)

    access_token = create_access_token(
        user.id, user.role_id, permissions,
        full_name=user.full_name,
        service_id=user.service_id,
        parcelle_id=user.parcelle_id,
        forest_ids=forest_ids,
    )
    refresh_token = create_refresh_token(user.id)

    await redis.setex(
        f"{REFRESH_TOKEN_PREFIX}{refresh_token}",
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        str(user.id),
    )

    asyncio.create_task(emit_security_event(
        event="login_success",
        email=user.email,
        role=role_name,
        ip=ip,
        failed_attempts=0,
    ))

    return access_token, refresh_token

async def refresh(refresh_token:str,db:AsyncSession,redis:aioredis.Redis):
    try:
        payload=decode_token(refresh_token)
        if payload.get("type")!="refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Invalid Token Type")
        user_id=int(payload["sub"])
    except(JWTError,ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Refresh Token")
    
    stored=await redis.get(f"{REFRESH_TOKEN_PREFIX}{refresh_token}")
    if not stored or int(stored)!=user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Refresh Token Revoked")
    
    result=await db.execute(select(User).where(User.id==user_id))
    user=result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Account not activated")
    
    permissions=user.role.permissions if user.role else []

    # ← Query the join table instead 
    forest_ids = await get_supervisor_forest_ids(user.id, db)
    
    new_access_token=create_access_token(
        user.id,
        user.role_id,
        permissions,
        full_name=user.full_name,
        service_id=user.service_id,
        parcelle_id=user.parcelle_id,
        forest_ids=forest_ids
        )
    return new_access_token

async def logout(refresh_token:str,redis:aioredis.Redis):
    await redis.delete(f"{REFRESH_TOKEN_PREFIX}{refresh_token}")

async def activate_account(token:str,password:str,db:AsyncSession):
    result=await db.execute(select(User).where(User.activation_token==token))
    user=result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Invalid Activation Token")
    if user.activation_token_expires and user.activation_token_expires<datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Activation Token Expired")
    
    user.hashed_password=hash_password(password)
    user.is_active=True
    user.activation_token=None
    user.activation_token_expires=None
    await db.commit()

async def _get_failed_attempts(redis: aioredis.Redis, ip: str) -> int:
    val = await redis.get(f"{FAILED_LOGIN_PREFIX}{ip}")
    return int(val) if val else 0

async def _increment_failed(redis: aioredis.Redis, ip: str) -> int:
    key = f"{FAILED_LOGIN_PREFIX}{ip}"
    count = await redis.incr(key)
    await redis.expire(key, FAILED_LOGIN_TTL_SECONDS)
    return count

async def _reset_failed(redis: aioredis.Redis, ip: str) -> None:
    await redis.delete(f"{FAILED_LOGIN_PREFIX}{ip}")
