from fastapi import APIRouter,Depends,HTTPException,status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.role import Role
from app.schemas.role_schema import RoleCreate,RoleResponse,RoleUpdate
from app.utils.deps import require_permission

router=APIRouter(prefix="/roles",tags=["Roles"])

VALID_PERMISSONS={
    "parcelle:create", "parcelle:read", "parcelle:update", "parcelle:delete",
    "user:create", "user:read", "user:update", "user:delete",
    "role:create", "role:read", "role:update", "role:delete",
    "forest:create", "forest:read", "forest:update", "forest:delete",
    "assignment:create", "assignment:read", "assignment:delete",
    "incident:create","incident:read", "incident:update", "incident:validate",
    "service:create", "service:read", "service:update", "service:delete",
    "analytics:read",
}

@router.get("",response_model=list[RoleResponse])
async def list_roles(
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("role:read"))
):
    result=await db.execute(select(Role))
    return list(result.scalars().all())

@router.post("",response_model=RoleResponse,status_code=status.HTTP_201_CREATED)
async def create_role(
    data:RoleCreate,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("role:create"))
):
    invalid=set(data.permissions)-VALID_PERMISSONS
    if invalid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail=f"Invalid permissions: {invalid}")
    
    existing=await db.execute(select(Role).where(Role.name==data.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,detail="Role name already exisits")
    
    role=Role(name=data.name,permissions=data.permissions,description=data.description)
    db.add(role)
    await db.commit()
    await db.refresh(role)
    return role

@router.put("/{role_id}",response_model=RoleResponse)
async def update_role(
    role_id:int,
    data:RoleUpdate,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("role:update"))
):
    result=await db.execute(select(Role).where(Role.id==role_id))
    role=result.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail='Role Not Found')
    
    if data.name is not None:
        role.name=data.name
    if data.permissions is not None:
        invalid=set(data.permissions)-VALID_PERMISSONS
        if invalid:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail=f"Invalid permissions: {invalid}")
        role.permissions=data.permissions
    if data.description is not None:
        role.description=data.description

    await db.commit()
    await db.refresh(role)
    return role

@router.delete("/{role_id}",status_code=status.HTTP_204_NO_CONTENT)
async def delete_role(
    role_id:int,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("role:delete"))
):
    result=await db.execute(select(Role).where(Role.id==role_id))
    role=result.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail='Role Not Found')
    await db.delete(role)
    await db.commit()
