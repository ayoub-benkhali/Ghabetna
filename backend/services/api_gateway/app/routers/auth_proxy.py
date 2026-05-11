import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings

router=APIRouter(prefix="/api/auth",tags=["Auth"])

async def _proxy(path:str,request:Request)->Response:
    body=await request.body()
    headers = {"Content-Type": request.headers.get("Content-Type", "application/json")}

    # Inject real client IP only for login, so auth-service can track it
    if path == "/login":
        client_ip = request.headers.get("X-Forwarded-For") or \
                    (request.client.host if request.client else "0.0.0.0")
        headers["X-Forwarded-For"] = client_ip


    async with httpx.AsyncClient(base_url=settings.AUTH_SERVICE_URL) as client:
        resp=await client.request(
            method=request.method,
            url=f"/auth{path}",
            content=body,
            headers=headers
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
