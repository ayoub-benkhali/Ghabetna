import httpx
from sqlalchemy import select
from app.config import settings
from fastapi import status,HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User


async def _validate_parcelle(parcelle_id:int)->None:
    """
    Calls forest_service to confirm the parcelle exists.
    Raises 404 if not found, 503 if forest_service is unreachable.
    Note: we don't have the forest_id here, so we use the flat lookup endpoint.
    """
    try:
        async with httpx.AsyncClient(base_url=settings.FOREST_SERVICE_URL,timeout=5.0) as client:
            resp=await client.get(f"/parcelles/{parcelle_id}")
        if resp.status_code==404:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail=f"Parcelle {parcelle_id} Not Found")
        if resp.status_code!=200:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY,detail="Forest service returned an unexpected Error")
    except httpx.RequestError:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE,detail="Forest Service is Unreachable")
    
async def _get_agent(user_id:int,db:AsyncSession)->User:
    result=await db.execute(select(User).where(User.id==user_id))
    user=result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="User Not Found")
    return user

async def _validate_forest(forest_id:int)->None:
    try:
        async with httpx.AsyncClient(base_url=settings.FOREST_SERVICE_URL,timeout=5.0) as client:
            resp=await client.get(f"/forests-internal/{forest_id}")
        if resp.status_code==404:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail=f"Forest {forest_id} Not Found")
        if resp.status_code!=200:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY,detail="Forest service returned an unexpected Error")
    except httpx.RequestError:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE,detail="Forest Service is Unreachable")