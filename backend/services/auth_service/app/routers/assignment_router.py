from fastapi import APIRouter,Depends, HTTPException, status
from app.database import get_db
from app.schemas.user_schema import UserResponse
from app.utils.deps import require_permission
from app.schemas.assignment_schema import AssignmentResponse,AssignRequest,SupervisorAssignmentResponse,SupervisorAssignRequest
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.assignment_service import _get_agent,_validate_parcelle,_validate_forest
from sqlalchemy import select
from app.models.user import User

router=APIRouter(prefix="/assignments",tags=["Assignments"])

@router.post("/users/{user_id}",response_model=AssignmentResponse,summary="Assign an agent to a parcelle (admin only)")
async def assign_agent(user_id:int,data:AssignRequest,db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:create"))):
    user=await _get_agent(user_id,db)
    
    await _validate_parcelle(data.parcelle_id)

    user.parcelle_id=data.parcelle_id
    await db.commit()
    await db.refresh(user)
    return AssignmentResponse(user_id=user.id,parcelle_id=user.parcelle_id)

@router.delete("/users/{user_id}",response_model=AssignmentResponse,summary="Remove a user's parcelle assignment (admin only)")
async def unassign_agent(user_id:int,db: AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:delete"))):
    user=await _get_agent(user_id,db)
    user.parcelle_id=None
    await db.commit()
    await db.refresh(user)
    return AssignmentResponse(user_id=user.id,parcelle_id=None)

@router.get("/users/{user_id}",response_model=AssignmentResponse,summary="Get a user's current parcelle assignment")
async def get_user_assignment(user_id:int,db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:read"))):
    user=await _get_agent(user_id,db)
    return AssignmentResponse(user_id=user.id,parcelle_id=user.parcelle_id)

@router.get("/parcelles/{parcelle_id}/agents",response_model=list[UserResponse],summary="Get all agents assigned to a parcelle")
async def get_agents_for_parcelle(parcelle_id:int,db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:read"))):
    result=await db.execute(select(User).where(User.parcelle_id==parcelle_id))
    return list(result.scalars().all())

@router.get("",response_model=list[AssignmentResponse],summary="List all active assignments")
async def list_asignments(db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:read"))):
    result=await db.execute(select(User).where(User.parcelle_id.is_not(None)))
    return[
        AssignmentResponse(user_id=u.id,parcelle_id=u.parcelle_id)
        for u in result.scalars().all()
    ]

# ── Supervisor ↔ Forest assignments ───────────────────────────────────────

@router.post("/supervisors/{user_id}",response_model=SupervisorAssignmentResponse,summary="Assign a supervisor to a forest (admin only)")
async def assign_supervisor(user_id:int,data:SupervisorAssignRequest,db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:create"))):
    user=await _get_agent(user_id,db)

    if user.forest_id is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,detail=f"User {user_id} is already assigned to forest {user.forest_id}. Unassign first")
    
    await _validate_forest(data.forest_id)
    user.forest_id=data.forest_id
    await db.commit()
    await db.refresh(user)
    return SupervisorAssignmentResponse(user_id=user.id,forest_id=user.forest_id)

@router.delete(
    "/supervisors/{user_id}",
    response_model=SupervisorAssignmentResponse,
    summary="Remove a supervisor's forest assignment (admin only)",
)
async def unassign_supervisor(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    _: None = Depends(require_permission("assignment:delete")),
):
    user = await _get_agent(user_id, db)
    user.forest_id = None
    await db.commit()
    await db.refresh(user)
    return SupervisorAssignmentResponse(user_id=user.id, forest_id=None)


@router.get("/supervisors/{user_id}",response_model=SupervisorAssignmentResponse, summary="Get a supervisor's current forest assignment")
async def get_supervisor_assignment(user_id:int,db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:read"))):
    user=await _get_agent(user_id,db)
    return SupervisorAssignmentResponse(user_id=user.id,forest_id=user.forest_id)

@router.get("/forests/{forest_id}/supervisors",response_model=list[UserResponse],summary="Get all supervisors assigned to a forest")
async def get_supervisors_for_forest(forest_id:int,db:AsyncSession=Depends(get_db),_:None=Depends(require_permission("assignment:read"))):
    await _validate_forest(forest_id=forest_id)
    result=await db.execute(select(User).where(User.forest_id==forest_id))
    return list(result.scalars().all())