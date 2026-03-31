import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings

router=APIRouter(prefix="/api/auth",tags=["Auth"])

async def _proxy(path:str,request:Request)->Response:
    body=await request.body()
    async with httpx.AsyncClient(base_url=settings.AUTH_SERVICE_URL) as client:
        resp=await client.request(
            method=request.method,
            url=f"/auth{path}",
            content=body,
            headers={"Content-Type":request.headers.get("Content-Type","application/json")}
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type")
    )

@router.post("/login")
async def login(request:Request):
    return await _proxy("/login",request)

@router.post("/refresh")
async def refresh(request:Request):
    return await _proxy("/refresh",request)

@router.post("/logout")
async def logout(request:Request):
    return await _proxy("/logout",request)

@router.post("/activate")
async def activate(request:Request):
    return await _proxy("/activate",request)
