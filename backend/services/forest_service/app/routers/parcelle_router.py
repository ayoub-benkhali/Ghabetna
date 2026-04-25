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
    Internal endpoint: given a lat/lng point, identify which forest (and
    optionally which parcelle) contains it.
 
    Lookup strategy (two steps):
 
    Step 1 — Parcelle match:
        Query for a parcelle whose boundary contains the point.  If found,
        return both the parcelle and its parent forest.  This is the happy
        path for forests that have parcelles drawn.
 
    Step 2 — Forest fallback:
        If no parcelle matches, check whether the point falls inside a
        forest boundary directly.  This handles two real-world cases:
          a) A forest exists but has no parcelles drawn yet.
          b) A forest has some parcelles, but the reported point is in a
             part of the forest that isn't covered by any of them.
        In this case we return the forest with parcelle_id=None so the
        incident is still correctly linked to its forest.
 
    Returns 404 only when the point is outside every registered forest.
    """
    point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
 
    # ── Step 1: try to find a matching parcelle ───────────────────────────
    parcelle_result = await db.execute(
        select(Parcelle, Forest)
        .join(Forest, Forest.id == Parcelle.forest_id)
        .where(ST_Within(point, Parcelle.boundary))
        .limit(1)
    )
    parcelle_row = parcelle_result.first()
 
    if parcelle_row is not None:
        parcelle, forest = parcelle_row
        return ParcelleLocationResponse(
            parcelle_id=parcelle.id,
            parcelle_name=parcelle.name,
            forest_id=forest.id,
            forest_name=forest.name,
        )
 
    # ── Step 2: fall back to forest boundary ─────────────────────────────
    # Only attempt this for forests that have a boundary drawn
    # (boundary is nullable on the Forest model).
    forest_result = await db.execute(
        select(Forest)
        .where(
            Forest.boundary.isnot(None),
            ST_Within(point, Forest.boundary),
        )
        .limit(1)
    )
    forest = forest_result.scalar_one_or_none()
 
    if forest is not None:
        return ParcelleLocationResponse(
            parcelle_id=None,
            parcelle_name=None,
            forest_id=forest.id,
            forest_name=forest.name,
        )
 
    # ── Point is outside every registered forest ──────────────────────────
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="No forest or parcelle found at the given coordinates",
    )

# Flat lookup used internally by auth_service for assignment validation
@flat_router.get("/{parcelle_id}",response_model=ParcelleResponse)
async def get_parcelle_flat(parcelle_id:int,db:AsyncSession=Depends(get_db)):
    result=await db.execute(select(Parcelle).where(Parcelle.id==parcelle_id))
    p=result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Parcelle Not Found")
    return _to_response(p)

