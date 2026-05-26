import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy import select
from app.models.role import Role
from app.models.user import User
from app.models.service import Service
from app.utils.password import hash_password
from app.database import Base
import os

"""
Run with: docker compose exec auth-service python seed.py
Creates default roles + admin, supervisor and agent test users.
"""

AUTH_DATABASE_URL = os.environ["AUTH_DATABASE_URL"]

ROLES_DATA = [
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
            "analytics:read",
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
            "analytics:read",
        ],
    },
    {
        "name": "agent",
        "description": "Agent forestier de terrain",
        "permissions": [
            "forest:read",
            "incident:create", "incident:read",
        ],
    },
]

# email / full_name / password / role_name
TEST_USERS = [
    ("admin@ghabetna.tn",      "Administrateur Ghabetna", "Admin123",      "admin"),
    ("supervisor@ghabetna.tn", "Superviseur Test",        "Supervisor123", "supervisor"),
    ("agent@ghabetna.tn",      "Agent Test",              "Agent123",      "agent"),
]


async def seed():
    engine = create_async_engine(AUTH_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with SessionLocal() as db:

        # ── 1. Upsert roles ───────────────────────────────────────────────────
        role_ids: dict[str, int] = {}

        for r in ROLES_DATA:
            result = await db.execute(select(Role).where(Role.name == r["name"]))
            role = result.scalar_one_or_none()
            if not role:
                role = Role(**r)
                db.add(role)
                await db.flush()
                print(f"  [role]  created  → {r['name']}")
            else:
                print(f"  [role]  exists   → {r['name']}")
            role_ids[r["name"]] = role.id

        await db.commit()

        # ── 2. Create test users ──────────────────────────────────────────────
        for email, full_name, password, role_name in TEST_USERS:
            result = await db.execute(select(User).where(User.email == email))
            if result.scalar_one_or_none():
                print(f"  [user]  exists   → {email}")
                continue

            user = User(
                email=email,
                full_name=full_name,
                role_id=role_ids[role_name],
                hashed_password=hash_password(password),
                is_active=True,
                activation_token=None,
            )
            db.add(user)
            await db.flush()
            print("──────────────────────────────────────────────")
            print(f"  [user]  created  → {email}  /  {password}  (role: {role_name})")
            print("──────────────────────────────────────────────")

        await db.commit()

    await engine.dispose()
    print("\nSeed complete.")


asyncio.run(seed())