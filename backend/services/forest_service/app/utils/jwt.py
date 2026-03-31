from typing import Any
from jose import jwt
from app.config import settings

def decode_token(token:str)-> dict[str,Any]:
    return jwt.decode(token,settings.JWT_SECRET,algorithms=[settings.JWT_ALGORITHM])
