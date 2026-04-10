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

@router.api_route("", methods=["GET","POST"])
async def incidents_root(request: Request):
    await verify_and_inject(request)
    qs = str(request.url.query)
    suffix = f"?{qs}" if qs and request.method == "GET" else ""
    return await _proxy(suffix, request)

@router.api_route("/mine", methods=["GET"])
async def my_incidents(request: Request):
    await verify_and_inject(request)
    return await _proxy("/mine", request)

@router.api_route("/{incident_id}", methods=["GET","PATCH"])
async def incident_by_id(incident_id: int, request: Request):
    await verify_and_inject(request)
    return await _proxy(f"/{incident_id}", request)

@router.api_route("", methods=["GET"])          # list all (supervisor)
async def list_incidents(request: Request):
    await verify_and_inject(request)
    # forward query params too
    qs = str(request.url.query)
    path = f"?{qs}" if qs else ""
    return await _proxy(path, request)