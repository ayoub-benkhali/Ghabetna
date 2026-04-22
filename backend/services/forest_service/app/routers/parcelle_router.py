from fastapi import APIRouter,Depends,HTTPException,status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.schemas.parcelle_schema import ParcelleLocationResponse, ParcelleUpdate,ParcelleCreate,ParcelleResponse
from app.services import parcelle_service
from app.utils.deps import require_permission
from app.models.parcelle import Parcelle
from app.services.parcelle_service import _to_response
from app.models.forest import Forest
from geoalchemy2.functions import ST_Within,ST_SetSRID,ST_MakePoint

router=APIRouter(prefix="/forests/{forest_id}/parcelles",tags=["parcelles"])


@router.get("",response_model=list[ParcelleResponse])
async def list_parcelles(forest_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:read"))):
    return await parcelle_service.get_parcelles(forest_id,db)

@router.post("",response_model=ParcelleResponse,status_code=201)
async def create_parcelle(forest_id:int,data:ParcelleCreate,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:create"))):
    return await parcelle_service.create_parcelle(forest_id,data,db)

@router.get("/{parcelle_id}",response_model=ParcelleResponse)
async def get_parcelle(forest_id:int,parcelle_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:read"))):
    return await parcelle_service.get_parcelle(forest_id,parcelle_id,db)

@router.put("/{parcelle_id}",response_model=ParcelleResponse)
async def update_parcelle(forest_id:int,parcelle_id:int,data:ParcelleUpdate,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:update"))):
    return await parcelle_service.update_parcelle(forest_id,parcelle_id,data,db)

@router.delete("/{parcelle_id}",status_code=204)
async def delete_parcelle(forest_id:int,parcelle_id:int,db:AsyncSession=Depends(get_db),_=Depends(require_permission("parcelle:delete"))):
    await parcelle_service.delete_parcelle(parcelle_id,db)

flat_router = APIRouter(prefix="/parcelles", tags=["parcelles-internal"], include_in_schema=False)

@flat_router.get("/by-point", response_model=ParcelleLocationResponse)
async def get_parcelle_by_point(
    lat: float,
    lng: float,
    db: AsyncSession = Depends(get_db),
):
    """
    Internal endpoint: given a lat/lng point, return the parcelle
    (and its parent forest) whose boundary contains that point.
    Returns 404 if the point falls outside all known parcelles.
    """
    point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)

    result = await db.execute(
        select(Parcelle, Forest)
        .join(Forest, Forest.id == Parcelle.forest_id)
        .where(ST_Within(point, Parcelle.boundary))
        .limit(1)
    )
    row = result.first()

    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No parcelle found at the given coordinates",
        )

    parcelle, forest = row
    return ParcelleLocationResponse(
        parcelle_id=parcelle.id,
        parcelle_name=parcelle.name,
        forest_id=forest.id,
        forest_name=forest.name,
    )

# Flat lookup used internally by auth_service for assignment validation
@flat_router.get("/{parcelle_id}",response_model=ParcelleResponse)
async def get_parcelle_flat(parcelle_id:int,db:AsyncSession=Depends(get_db)):
    result=await db.execute(select(Parcelle).where(Parcelle.id==parcelle_id))
    p=result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Parcelle Not Found")
    return _to_response(p)

