from datetime import datetime
from pydantic import BaseModel
from typing import Optional

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


class ParcelleLocationResponse(BaseModel):
    """Returned by the internal point-in-polygon lookup."""
    parcelle_id: Optional[int] = None
    parcelle_name: Optional[str] = None
    forest_id: int
    forest_name: str
