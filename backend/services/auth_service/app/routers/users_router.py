from fastapi import APIRouter,Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.schemas.user_schema import UserCreate,UserUpdate,UserWithRoleResponse
from app.services import user_service
from app.utils.deps import require_permission,get_current_user
from app.models.user import User

router=APIRouter(prefix="/users",tags=["Users"])

@router.get("",response_model=list[UserWithRoleResponse])
async def list_users(
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("user:read"))
):
    return await user_service.get_users(db)

@router.post("",response_model=UserWithRoleResponse,status_code=201)
async def create_user(
    data:UserCreate,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("user:create"))
):
    return await user_service.create_user(data,db)

@router.get("/me",response_model=UserWithRoleResponse)
async def get_me(db:AsyncSession=Depends(get_db),current_user:User=Depends(get_current_user)):
    return await user_service.get_user(current_user.id,db)

@router.put("/me", response_model=UserWithRoleResponse)
async def update_me(
    data: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await user_service.update_user(current_user.id, data, db)

@router.get("/{user_id}",response_model=UserWithRoleResponse)
async def get_user(
    user_id:int,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("user:read"))
):
    return await user_service.get_user(user_id,db)

@router.put("/{user_id}",response_model=UserWithRoleResponse)
async def update_user(
    user_id:int,
    data:UserUpdate,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("user:update"))
):
    return await user_service.update_user(user_id,data,db)

@router.delete("/{user_id}",status_code=204)
async def deactivate_user(
    user_id:int,
    db:AsyncSession=Depends(get_db),
    _:None=Depends(require_permission("user:delete"))
):
    await user_service.delete_user(user_id,db)
