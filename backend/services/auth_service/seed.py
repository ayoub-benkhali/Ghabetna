import asyncio
from sqlalchemy.ext.asyncio import AsyncSession,create_async_engine,async_sessionmaker
from sqlalchemy import select
from app.models.role import Role
from app.models.user import User
from app.models.service import Service
from app.utils.password import hash_password
from app.database import Base
import os

"""
Run with: docker compose exec auth-service python seed.py
creates default roles and admin User
"""

AUTH_DATABASE_URL=os.environ["AUTH_DATABASE_URL"]

async def seed():
    engine=create_async_engine(AUTH_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    SessionLocal=async_sessionmaker(engine,class_=AsyncSession,expire_on_commit=False)
    async with SessionLocal() as db:
        roles_data=[
            {
                "name": "admin",
                "description": "Administrateur système",
                "permissions": [
                    "user:create", "user:read", "user:update", "user:delete",
                    "role:create", "role:read", "role:update", "role:delete",
                    "forest:create", "forest:read", "forest:update", "forest:delete",
                    "parcelle:create", "parcelle:read", "parcelle:update", "parcelle:delete",
                    "service:create", "service:read", "service:update", "service:delete",
                    "assignment:create", "assignment:read", "assignment:delete",
                    "incident:read", "incident:update", "incident:validate",
                    "score:read", "score:update",
                    "analytics:read",
                    "notification:send",
                ],
            },
            {
                "name": "supervisor",
                "description": "Superviseur opérationnel",
                "permissions": [
                    "user:read",
                    "forest:read",
                    "service:read",
                    "parcelle:read",
                    "assignment:create", "assignment:read", "assignment:delete",
                    "incident:read", "incident:update", "incident:validate",
                    "score:read", "score:update",
                    "analytics:read",
                ],
            },
            {
                "name": "agent",
                "description": "Agent forestier de terrain",
                "permissions": [
                    "forest:read",
                    "incident:create","incident:read",
                    "score:read",
                ],
            },
        ]
        admin_role_id=None
        for r in roles_data:
            existing=await db.execute(select(Role).where(Role.name==r["name"]))
            if not existing.scalar_one_or_none():
                role=Role(**r)
                db.add(role)
                await db.flush()
                if r["name"]=="admin":
                    admin_role_id=role.id
            else:
                existing_role=(await db.execute(select(Role).where(Role.name=="admin"))).scalar_one_or_none()
                if r["name"]=="admin" and existing_role:
                    admin_role_id=existing_role.id
        await db.commit()

        admin_exists=await db.execute(select(User).where(User.email=="admin@gmail.com"))
        if not admin_exists.scalar_one_or_none() and admin_role_id:
            admin=User(
                email="admin@gmail.com",
                full_name="Adminstrateur Ghabetna",
                role_id=admin_role_id,
                hashed_password=hash_password("Admin123"),
                is_active=True
            )
            db.add(admin)
            await db.commit()
            print("Admin Created: admin@gmail.com / Admin123")
        else:
            print("Admin already exists")
        
        print("Seed Complete")
    await engine.dispose()
asyncio.run(seed())
