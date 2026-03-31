import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router=APIRouter(prefix="/api/forests",tags=["Parcelles"])

async def _proxy(path: str, request: Request, payload: dict | None) -> Response:
    body = await request.body()
    headers = {
        "Content-Type": request.headers.get("Content-Type", "application/json"),
        "Authorization": request.headers.get("Authorization", ""),
    }
    async with httpx.AsyncClient(base_url=settings.FOREST_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url=f"/forests{path}",
            content=body,
            headers=headers,
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )

@router.api_route("/{forest_id}/parcelles",methods=["GET","POST"])
async def parcelles_root(forest_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/{forest_id}/parcelles",request,payload)

@router.api_route("/{forest_id}/parcelles/{parcelle_id}",methods=["GET", "PUT", "DELETE"])
async def parcelle_by_id(forest_id:int,parcelle_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/{forest_id}/parcelles/{parcelle_id}",request,payload)
