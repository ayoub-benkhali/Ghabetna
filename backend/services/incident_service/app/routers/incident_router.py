import os,shutil,uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select,and_
from typing import Optional
from geoalchemy2.functions import ST_SetSRID,ST_MakePoint
from app.database import get_db
from app.models.incident import Incident, IncidentCategory, IncidentStatus
from app.schemas.incident_schema import IncidentResponse, IncidentStatusUpdate
from app.utils.deps import require_permission, get_current_user_payload
from app.config import settings

router=APIRouter(prefix="/incidents", tags=["Incidents"])

CRITICAL_CATEGORIES={IncidentCategory.REFUGE_SUSPECT,IncidentCategory.TRAFIC}

def _save_image(file:UploadFile,agent_id:int)->str:
    os.makedirs(settings.UPLOAD_DIR,exist_ok=True)
    ext=os.path.splitext(file.filename or "img.jpg")[1]
    filename=f"{agent_id}_{uuid.uuid4().hex}{ext}"
    path=os.path.join(settings.UPLOAD_DIR,filename)
    with open(path,"wb") as buffer:
        shutil.copyfileobj(file.file,buffer)
    return f"/uploads/{filename}"


# Agent endpoints
@router.post("",response_model=IncidentResponse,status_code=201,dependencies=[Depends(require_permission("incident:create"))])
async def create_incident(
    category: IncidentCategory = Form(...),
    description: str = Form(...),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    parcelle_id: Optional[int] = Form(None),
    forest_id: Optional[int] = Form(None),
    image: Optional[UploadFile] = File(None),
    payload: dict = Depends(get_current_user_payload),
    db: AsyncSession = Depends(get_db),
    ):
    image_url=None
    if image and image.filename:
        image_url=_save_image(image,payload["sub"])

    location=None
    if latitude is not None and longitude is not None:
        location=ST_SetSRID(ST_MakePoint(longitude,latitude),4326)

    incident=Incident(
        agent_id=int(payload["sub"]),
        agent_name=payload.get("full_name", ""),
        category=category,
        description=description,
        image_url=image_url,
        location=location,
        latitude=latitude,
        longitude=longitude,
        parcelle_id=parcelle_id,
        forest_id=forest_id,
        is_critical=category in CRITICAL_CATEGORIES,
    )
    db.add(incident)
    await db.commit()
    await db.refresh(incident)
    return incident

@router.get("/mine", response_model=list[IncidentResponse],
            dependencies=[Depends(require_permission("incident:read"))])
async def my_incidents(
    payload: dict = Depends(get_current_user_payload),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Incident)
        .where(Incident.agent_id == int(payload["sub"]))
        .order_by(Incident.created_at.desc())
    )
    return result.scalars().all()

@router.get("/{incident_id}", response_model=IncidentResponse,
            dependencies=[Depends(require_permission("incident:read"))])
async def get_incident(incident_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident

# Admin/supervisor endpoints
@router.get("", response_model=list[IncidentResponse],
            dependencies=[Depends(require_permission("incident:read"))])
async def list_all_incidents(
    status: Optional[IncidentStatus] = None,
    category: Optional[IncidentCategory] = None,
    forest_id: Optional[int] = None,
    parcelle_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
):
    filters = []
    if status:
        filters.append(Incident.status == status)
    if category:
        filters.append(Incident.category == category)
    if forest_id:
        filters.append(Incident.forest_id == forest_id)
    if parcelle_id:
        filters.append(Incident.parcelle_id == parcelle_id)

    q = select(Incident).order_by(Incident.created_at.desc())
    if filters:
        q = q.where(and_(*filters))
    result = await db.execute(q)
    return result.scalars().all()

# PATCH status (supervisor)
@router.patch("/{incident_id}", response_model=IncidentResponse,
              dependencies=[Depends(require_permission("incident:update"))])
async def update_incident_status(
    incident_id: int,
    body: IncidentStatusUpdate,
    payload: dict = Depends(get_current_user_payload),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Incident).where(Incident.id == incident_id))
    incident = result.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    incident.status = body.status
    if body.supervisor_comment:
        incident.supervisor_comment = body.supervisor_comment
    incident.supervisor_id = int(payload["sub"])
    await db.commit()
    await db.refresh(incident)
    return incident