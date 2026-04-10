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

REFRESH_TOKEN_PREFIX="refresh:"
BLACKLIST_PREFIX="blacklist:"

async def login(email:str,password:str,db:AsyncSession,redis:aioredis.Redis):
    result=await db.execute(select(User).where(User.email==email))
    user=result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Invalid Email")
    if not user.is_active or not user.hashed_password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Account not activated")
    if not verify_password(password,user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,detail="Invalid Password")
    
    permissions=user.role.permissions if user.role else []
    access_token=create_access_token(
        user.id,
        user.role_id,
        permissions,
        full_name=user.full_name,
        service_id=user.service_id,
        parcelle_id=user.parcelle_id,
        forest_id=user.forest_id
        )
    refresh_token=create_refresh_token(user.id)

    await redis.setex(
        f"{REFRESH_TOKEN_PREFIX}{refresh_token}",
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        str(user.id)
    )

    return access_token,refresh_token

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
    new_access_token=create_access_token(
        user.id,
        user.role_id,
        permissions,
        full_name=user.full_name,
        service_id=user.service_id,
        parcelle_id=user.parcelle_id,
        forest_id=user.forest_id
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
