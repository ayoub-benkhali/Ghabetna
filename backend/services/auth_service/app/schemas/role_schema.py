from datetime import datetime
from typing import List,Optional
from pydantic import BaseModel

class RoleCreate(BaseModel):
    name:str
    permissions:List[str]=[]
    description:str|None=None

class RoleUpdate(BaseModel):
    name:str|None=None
    permissions:List[str]|None=None
    description:str|None=None

class RoleResponse(BaseModel):
    id:int
    name:str
    permissions: List[str]
    description:str|None=None
    created_at:datetime
    updated_at:datetime

    class Config:
        from_attributes=True
