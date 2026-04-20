from datetime import datetime
from pydantic import BaseModel
from typing import Optional
from app.models.incident import IncidentCategory, IncidentStatus

class IncidentCreate(BaseModel):
    category: IncidentCategory
    description: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    parcelle_id: Optional[int] = None
    forest_id: Optional[int] = None
    is_critical: bool = False

class IncidentResponse(BaseModel):
    id: int
    agent_id: int
    agent_name: str
    category: IncidentCategory
    description: str
    image_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    parcelle_id: Optional[int] = None
    forest_id: Optional[int] = None
    supervisor_comment: Optional[str] = None
    supervisor_id: Optional[int] = None
    supervisor_name: Optional[str] = None
    status: IncidentStatus
    is_critical: bool
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class IncidentStatusUpdate(BaseModel):
    status:IncidentStatus
    supervisor_comment:Optional[str]=None