from datetime import datetime,timedelta,timezone
from fastapi import HTTPException,status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.models.role import Role
from app.schemas.user_schema import UserCreate,UserUpdate
from app.services.email_service import send_activation_email

async def create_user(data: UserCreate,db:AsyncSession)->User:
    existing=await db.execute(select(User).where(User.email==data.email))
    existing_user=existing.scalar_one_or_none()
    if existing_user:
        # If user exists but was never activated (no password set), resend activation
        if not existing_user.is_active and existing_user.hashed_password is None:
            token=existing_user.generate_activation_token()
            existing_user.activation_token_expires=datetime.now(timezone.utc)+timedelta(hours=48)
            await db.commit()
            await db.refresh(existing_user)
            try:
                await send_activation_email(existing_user.email,existing_user.full_name,token)
            except Exception as e:
                print(f"[WARN] Email sending failed: {e}")
            return existing_user
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,detail="User Already Exists")

    role_result=await db.execute(select(Role).where(Role.id==data.role_id))
    if not role_result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Role Not Found")

    if data.service_id is not None:
        from app.models.service import Service
        svc_result=await db.execute(select(Service).where(Service.id==data.service_id))
        if not svc_result.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Service Not Found")

    user=User(email=data.email,full_name=data.full_name,role_id=data.role_id,service_id=data.service_id)
    token=user.generate_activation_token()
    user.activation_token_expires=datetime.now(timezone.utc)+timedelta(hours=48)

    db.add(user)
    await db.commit()
    await db.refresh(user)

    try:
        await send_activation_email(user.email,user.full_name,token)
    except Exception as e:
        print(f"[WARN] Email sending failed: {e}")

    return user

async def get_users(db:AsyncSession)-> list[User]:
    result=await db.execute(select(User))
    return list(result.scalars().all())

async def get_user(user_id:int,db:AsyncSession)->User:
    result= await db.execute(select(User).where(User.id==user_id))
    user=result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="User Not Found")
    return user

async def update_user(user_id:int,data:UserUpdate,db:AsyncSession)->User:
    user=await get_user(user_id,db)
    if data.full_name is not None:
        user.full_name=data.full_name
    if data.role_id is not None:
        role_result=await db.execute(select(Role).where(Role.id==data.role_id))
        if not role_result.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Role Not Found")
        user.role_id=data.role_id
    if data.is_active is not None:
        user.is_active=data.is_active
    if data.service_id is not None:
        from app.models.service import Service
        svc_result=await db.execute(select(Service).where(Service.id==data.service_id))
        if not svc_result.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Service Not Found")
        user.service_id=data.service_id
    await db.commit()
    await db.refresh(user)
    return user

async def delete_user(user_id:int,db:AsyncSession):
    user=await get_user(user_id,db)
    #soft delete for now
    user.is_active=False
    await db.commit()
