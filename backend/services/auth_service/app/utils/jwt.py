from datetime import datetime,timedelta,timezone
from typing import Any
from jose import JWTError,jwt
from app.config import settings

def create_access_token(
        user_id:int,
        role_id:int,
        permissions: list[str],
        full_name: str = "",
        service_id:int|None=None,
        parcelle_id:int|None=None,
        forest_ids: list[int] = [],

        )->str:
    expire=datetime.now(timezone.utc)+timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    payload={
        "sub":str(user_id),
        "role_id":role_id,
        "permissions":permissions,
        "full_name":full_name,
        "service_id":service_id,
        "parcelle_id":parcelle_id,
        "forest_ids": forest_ids,
        "type":"access",
        "exp":expire
    }
    return jwt.encode(payload,settings.JWT_SECRET,algorithm=settings.JWT_ALGORITHM)

def create_refresh_token(user_id:int)->str:
    expire=datetime.now(timezone.utc)+timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    payload={
        "sub":str(user_id),
        "type":"refresh",
        "exp":expire
    }
    return jwt.encode(payload,settings.JWT_SECRET,algorithm=settings.JWT_ALGORITHM)

def decode_token(token:str)->dict[str,Any]:
    #this raises a JWTError if invalid or expired token
    return jwt.decode(token,settings.JWT_SECRET,algorithms=[settings.JWT_ALGORITHM])
