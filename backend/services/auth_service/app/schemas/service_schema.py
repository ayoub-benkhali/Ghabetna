from datetime import datetime
from pydantic import BaseModel
from app.models.service import ServiceType

class ServiceCreate(BaseModel):
    name:str
    type:ServiceType
    description:str|None=None

class ServiceUpdate(BaseModel):
    name:str|None=None
    type:ServiceType |None=None
    description:str|None=None

class ServiceResponse(BaseModel):
    id:int
    name:str
    type:ServiceType
    description:str|None=None
    created_at:datetime
    class Config:
        from_attributes=True
