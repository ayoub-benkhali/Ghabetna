from datetime import datetime
from pydantic import BaseModel

class ForestCreate(BaseModel):
    name:str
    region:str|None=None
    description:str|None=None
    boundary_geojson:dict|None=None
    center_lat:float|None=None
    center_lng:float|None=None

class ForestUpdate(BaseModel):
    name:str|None=None
    region:str|None=None
    description:str|None=None
    boundary_geojson:dict|None=None
    center_lat:float|None=None
    center_lng:float|None=None

class ForestReponse(BaseModel):
    id:int
    name:str
    region:str|None
    description:str|None
    area_hectares:float|None
    center_lat:float|None
    center_lng:float|None
    boundary_geojson:dict|None
    parcelle_count: int
    created_at:datetime
    updated_at:datetime

    class Config:
        from_attributes=True
