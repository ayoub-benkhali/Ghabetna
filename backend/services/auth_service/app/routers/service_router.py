from fastapi import APIRouter,Depends,HTTPException,status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.service import Service
from app.schemas.service_schema import ServiceCreate,ServiceResponse,ServiceType,ServiceUpdate
from app.utils.deps import require_permission

router=APIRouter(prefix="/services",tags=["Services"])


@router.get("",response_model=list[ServiceResponse])
async def list_services(db:AsyncSession=Depends(get_db),_=Depends(require_permission("service:read"))):
    result=await db.execute(select(Service))
    return result.scalars().all()

@router.post("",response_model=ServiceResponse,status_code=201)
async def create_service(data:ServiceCreate,db:AsyncSession=Depends(get_db),_=Depends(require_permission("service:create"))):
    s=Service(**data.model_dump())
    db.add(s)
    await db.commit()
    await db.refresh(s)
    return s

@router.put("/{service_id}",response_model=ServiceResponse)
async def update_service(service_id:int,data:ServiceUpdate,db:AsyncSession=Depends(get_db),_=Depends(require_permission("service:update"))):
    result=await db.execute(select(Service).where(Service.id==service_id))
    s=result.scalar_one_or_none()
    if not s:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Service Not Found")
    for k,v in data.model_dump(exclude_none=True).items():
        setattr(s,k,v)
    await db.commit()
    await db.refresh(s)
    return s

@router.delete("/{service_id}",status_code=204)
async def delete_service(service_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("service:delete"))):
    result=await db.execute(select(Service).where(Service.id==service_id))
    s=result.scalar_one_or_none()
    if not s:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Service Not Found")
    await db.delete(s)
    await db.commit()
