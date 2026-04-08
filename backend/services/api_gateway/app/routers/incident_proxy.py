import httpx
from fastapi import APIRouter,Request,Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router = APIRouter(prefix="/api/incidents", tags=["Incidents"])

async def _proxy(path: str, request: Request) -> Response:
    body = await request.body()
    content_type = request.headers.get("Content-Type", "application/json")
    headers = {
        "Content-Type": content_type,
        "Authorization": request.headers.get("Authorization", ""),
    }
    async with httpx.AsyncClient(
        base_url=settings.INCIDENT_SERVICE_URL, timeout=30.0
    ) as client:
        resp = await client.request(
            method=request.method,
            url=f"/incidents{path}",
            content=body,
            headers=headers,
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )

@router.api_route("", methods=["POST"])
async def incidents_root(request: Request):
    await verify_and_inject(request)
    return await _proxy("", request)

@router.api_route("/mine", methods=["GET"])
async def my_incidents(request: Request):
    await verify_and_inject(request)
    return await _proxy("/mine", request)

@router.api_route("/{incident_id}", methods=["GET"])
async def incident_by_id(incident_id: int, request: Request):
    await verify_and_inject(request)
    return await _proxy(f"/{incident_id}", request)