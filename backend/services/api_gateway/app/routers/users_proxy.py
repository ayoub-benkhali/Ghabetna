import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router=APIRouter(prefix="/api/users",tags=["Users"])

async def _proxy(path:str,request:Request,payload:dict|None)-> Response:
    body=await request.body()
    headers={
        "Content-Type": request.headers.get("Content-Type","application/json"),
        "Authorization": request.headers.get("Authorization","")
    }
    async with httpx.AsyncClient(base_url=settings.AUTH_SERVICE_URL) as client:
        resp=await client.request(
            method=request.method,
            url=f"/users{path}",
            content=body,
            headers=headers
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type")
    )

@router.api_route("",methods=["GET","POST"])
async def users_root(request:Request):
    payload=await verify_and_inject(request)
    return await _proxy("",request,payload)

@router.api_route("/me",methods=["GET","PUT"])
async def users_me(request:Request):
    payload=await verify_and_inject(request)
    return await _proxy("/me",request,payload)

@router.api_route("/{user_id}",methods=["GET","PUT","DELETE"])
async def users_by_id(user_id:int,request:Request):
    payload=await verify_and_inject(request)
    return await _proxy(f"/{user_id}",request,payload)
