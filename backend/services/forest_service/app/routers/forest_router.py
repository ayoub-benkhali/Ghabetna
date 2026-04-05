from fastapi import APIRouter,Depends,HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.schemas.forest_schema import ForestCreate,ForestReponse,ForestUpdate
from app.services import forest_service
from app.utils.deps import require_permission
from app.services.forest_service import _to_response
from app.models.forest import Forest

router=APIRouter(prefix="/forests",tags=["forests"])

@router.get("",response_model=list[ForestReponse])
async def list_forests(
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("forest:read"))
):
    return await forest_service.get_forests(db)

@router.post("",response_model=ForestReponse,status_code=201)
async def create_forest(
    data:ForestCreate,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("forest:create"))
):
    return await forest_service.create_forest(data,db)

@router.get("/{forest_id}",response_model=ForestReponse)
async def get_forest(
    forest_id:int,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("forest:read"))
):
    return await forest_service.get_forest(forest_id,db)

@router.put("/{forest_id}",response_model=ForestReponse)
async def update_forest(
    forest_id:int,
    data:ForestUpdate,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("forest:update"))
):
    return await forest_service.update_forest(forest_id,data,db)

@router.delete("/{forest_id}",status_code=204)
async def delete_forest(
    forest_id:int,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("forest:delete"))
):
    await forest_service.delete_forest(forest_id,db)

flat_router=APIRouter(prefix="/forests-internal",include_in_schema=False)

@flat_router.get("/{forest_id}")
async def get_forest_flat(forest_id:int,db:AsyncSession=Depends(get_db)):
    result=await db.execute(select(Forest).where(Forest.id==forest_id))
    f=result.scalar_one_or_none()
    if not f:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Forest Not Found")
    return {"id":f.id} # auth_service only needs to know it exists
