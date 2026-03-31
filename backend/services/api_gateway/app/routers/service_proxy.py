import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router=APIRouter(prefix="/api/services",tags=["Services"])

async def _proxy(path: str, request: Request, payload: dict | None) -> Response:
    body = await request.body()
    headers = {
        "Content-Type": request.headers.get("Content-Type", "application/json"),
        "Authorization": request.headers.get("Authorization", ""),
    }
    async with httpx.AsyncClient(base_url=settings.AUTH_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url=f"/services{path}",
            content=body,
            headers=headers,
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )

@router.api_route("",methods=["GET","POST"])
async def services_rout(request:Request):
    payload=await verify_and_inject(request)
    return await _proxy("",request,payload)

@router.api_route("/{service_id}", methods=["GET", "PUT", "DELETE"])
async def service_by_id(service_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/{service_id}",request,payload)
