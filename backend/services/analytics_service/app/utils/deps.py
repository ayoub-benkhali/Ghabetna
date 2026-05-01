from fastapi import Depends,HTTPException,status
from fastapi.security import HTTPBearer,HTTPAuthorizationCredentials
from jose import JWTError
from app.utils.jwt import decode_token

security=HTTPBearer()

def require_permission(permission:str):
    async def checker(
            credentials:HTTPAuthorizationCredentials=Depends(security)
    ):
        try:
            payload=decode_token(credentials.credentials)
            perms=payload.get("permissions",[])
            if permission not in perms:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions"
                )
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Token"
            )
    return checker

async def get_current_user_payload(
        credentials: HTTPAuthorizationCredentials=Depends(security)
)->dict:
    try:
        payload=decode_token(credentials.credentials)
        return payload
    except JWTError:
        raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Token"
            )