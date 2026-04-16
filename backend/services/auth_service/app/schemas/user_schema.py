from datetime import datetime
from pydantic import BaseModel,EmailStr

class UserCreate(BaseModel):
    email:EmailStr
    full_name:str
    role_id:int
    service_id:int|None=None

class UserUpdate(BaseModel):
    full_name:str|None=None
    role_id:int|None=None
    is_active:bool|None=None
    service_id:int | None=None

class UserResponse(BaseModel):
    id:int
    email:str
    full_name:str
    role_id:int
    service_id:int|None=None
    parcelle_id:int|None=None
    forest_id:int|None=None
    is_active:bool
    created_at:datetime

    class Config:
        from_attributes=True

class RoleInUser(BaseModel):
    id:int
    name:str
    permissions:list[str]

    class Config:
        from_attributes=True

class UserWithRoleResponse(UserResponse):
    role:RoleInUser
