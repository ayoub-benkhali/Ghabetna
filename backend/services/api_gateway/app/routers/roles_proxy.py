import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router=APIRouter(prefix="/api/roles",tags=["Roles"])

async def _proxy(path:str,request:Request,payload:dict|None)->Response:
    body=await request.body()
    headers={
        "Content-Type":request.headers.get("Content-Type","application/json"),
        "Authorization": request.headers.get("Authorization","")
    }
    async with httpx.AsyncClient(base_url=settings.AUTH_SERVICE_URL) as client:
        resp=await client.request(
            method=request.method,
            url=f"/roles{path}",
            content=body,
            headers=headers
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type")
    )

@router.api_route("",methods=["GET","POST"])
async def roles_root(request:Request):
    payload=await verify_and_inject(request)
    return await _proxy("",request,payload)

@router.api_route("/{role_id}",methods=["GET", "PUT", "DELETE"])
async def roles_by_id(role_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/{role_id}",request,payload)
