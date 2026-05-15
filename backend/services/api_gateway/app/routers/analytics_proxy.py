import httpx
from fastapi import APIRouter, Request, Response
from app.config import settings
from app.middleware.rbac import verify_and_inject

router = APIRouter(prefix="/api/analytics", tags=["Analytics"])

async def _proxy(path: str, request: Request) -> Response:
    headers = {
        "Content-Type": request.headers.get("Content-Type", "application/json"),
        "Authorization": request.headers.get("Authorization", ""),
    }
    params = dict(request.query_params)
    async with httpx.AsyncClient(base_url=settings.ANALYTICS_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url=f"/analytics{path}",
            headers=headers,
            params=params,
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )

@router.get("/kpis")
async def kpis(request: Request):
    await verify_and_inject(request)
    return await _proxy("/kpis", request)

# Monthly trend line chart (kept at /daily for backwards compat)
@router.get("/daily")
async def daily(request: Request):
    await verify_and_inject(request)
    return await _proxy("/daily", request)

# Top 3 agents by incident count
@router.get("/top-agents")
async def top_agents(request: Request):
    await verify_and_inject(request)
    return await _proxy("/top-agents", request)

@router.get("/by-category")
async def by_category(request: Request):
    await verify_and_inject(request)
    return await _proxy("/by-category", request)

# Top 3 forests by incident count
@router.get("/density")
async def density(request: Request):
    await verify_and_inject(request)
    return await _proxy("/density", request)

@router.get("/peak-hours")
async def peak_hours(request: Request):
    await verify_and_inject(request)
    return await _proxy("/peak-hours", request)

# ── Security endpoints ────────────────────────────────────────────────────────

@router.get("/security/summary")
async def security_summary(request: Request):
    await verify_and_inject(request)
    # Security router is mounted at /security, NOT /analytics/security
    async with httpx.AsyncClient(base_url=settings.ANALYTICS_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url="/security/summary",
            headers={
                "Content-Type": request.headers.get("Content-Type", "application/json"),
                "Authorization": request.headers.get("Authorization", ""),
            },
            params=dict(request.query_params),
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )

@router.get("/security/alerts")
async def security_alerts(request: Request):
    await verify_and_inject(request)
    async with httpx.AsyncClient(base_url=settings.ANALYTICS_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url="/security/alerts",
            headers={
                "Content-Type": request.headers.get("Content-Type", "application/json"),
                "Authorization": request.headers.get("Authorization", ""),
            },
            params=dict(request.query_params),
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type"),
    )
