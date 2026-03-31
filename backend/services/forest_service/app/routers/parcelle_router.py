from fastapi import APIRouter,Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.schemas.parcelle_schema import ParcelleUpdate,ParcelleCreate,ParcelleResponse
from app.services import parcelle_service
from app.utils.deps import require_permission

router=APIRouter(prefix="/forests/{forest_id}/parcelles",tags=["parcelles"])

@router.get("",response_model=list[ParcelleResponse])
async def list_parcelles(forest_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:read"))):
    return await parcelle_service.get_parcelles(forest_id,db)

@router.post("",response_model=ParcelleResponse,status_code=201)
async def create_parcelle(forest_id:int,data:ParcelleCreate,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:create"))):
    return await parcelle_service.create_parcelle(forest_id,data,db)

@router.get("/{parcelle_id}",response_model=ParcelleResponse)
async def get_parcelle(parcelle_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:read"))):
    return await parcelle_service.get_parcelle(parcelle_id,db)

@router.put("/{parcelle_id}",response_model=ParcelleResponse)
async def update_parcelle(forest_id:int,parcelle_id:int,data:ParcelleUpdate,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:update"))):
    return await parcelle_service.update_parcelle(parcelle_id,data,db)

@router.delete("/{parcelle_id}",status_code=204)
async def delete_parcelle(forest_id:int,parcelle_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:delete"))):
    await parcelle_service.delete_parcelle(parcelle_id,db)
