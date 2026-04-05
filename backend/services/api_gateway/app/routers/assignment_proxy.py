import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router=APIRouter(prefix="/api/assignments",tags=["Assignments"])

async def _proxy(path: str, request: Request, payload: dict | None) -> Response:
    body = await request.body()
    headers = {
        "Content-Type": request.headers.get("Content-Type", "application/json"),
        "Authorization": request.headers.get("Authorization", ""),
    }
    async with httpx.AsyncClient(base_url=settings.AUTH_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url=f"/assignments{path}",
            content=body,
            headers=headers,
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )

@router.api_route("",methods=["GET"])
async def list_assignments(request:Request):
    payload=await verify_and_inject(request)
    return await _proxy("",request,payload)

@router.api_route("/users/{user_id}", methods=["GET", "POST", "DELETE"])
async def assignment_by_user(user_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/users/{user_id}",request,payload)

@router.api_route("/parcelles/{parcelle_id}/agents",methods=["GET"])
async def agents_for_parcelle(parcelle_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/parcelles/{parcelle_id}/agents",request,payload)

@router.api_route("/supervisors/{user_id}",methods=["GET", "POST", "DELETE"])
async def assignment_by_supervisor(user_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/supervisors/{user_id}",request,payload)

@router.api_route("/forests/{forest_id}/supervisors",methods=["GET"])
async def supervisors_for_forest(forest_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/forests/{forest_id}/supervisors", request, payload)
