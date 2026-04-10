from datetime import datetime
from pydantic import BaseModel

class ParcelleCreate(BaseModel):
    name:str
    description:str|None=None
    boundary_geojson:dict

class ParcelleUpdate(BaseModel):
    name:str|None=None
    description:str|None=None
    boundary_geojson:dict|None=None

class ParcelleResponse(BaseModel):
    id:int
    forest_id:int
    name:str
    description: str|None
    area_hectars:float|None
    boundary_geojson: dict
    created_at: datetime
    updated_at: datetime
    class Config:
        from_attributes=True
