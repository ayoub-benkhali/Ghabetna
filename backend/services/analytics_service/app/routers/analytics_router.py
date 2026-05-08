import httpx
from fastapi import APIRouter, Depends, Query, Request, HTTPException
from app.config import settings
from app.utils.deps import require_permission

router = APIRouter(prefix="/analytics", tags=["analytics"])


async def _call_incident(path: str, request: Request, params: dict|None = None):
    """Forward a request to incident_service, passing the JWT through."""
    headers = {"Authorization": request.headers.get("Authorization", "")}
    try:
        async with httpx.AsyncClient(base_url=settings.INCIDENT_SERVICE_URL, timeout=10.0) as client:
            resp = await client.get(f"/analytics{path}", headers=headers, params=params or {})
        resp.raise_for_status()
        return resp.json()
    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Incident Service is unreachable")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=e.response.text)


@router.get("/kpis", dependencies=[Depends(require_permission("analytics:read"))])
async def get_kpis(request: Request):
    return await _call_incident("/kpis", request)


@router.get("/daily", dependencies=[Depends(require_permission("analytics:read"))])
async def get_monthly_trend(request: Request, year: int = Query(default=None)):
    params = {"year": year} if year else {}
    return await _call_incident("/daily", request, params)


@router.get("/top-agents", dependencies=[Depends(require_permission("analytics:read"))])
async def get_top_agents(request: Request):
    return await _call_incident("/top-agents", request)


@router.get("/by-category", dependencies=[Depends(require_permission("analytics:read"))])
async def get_by_category(request: Request):
    return await _call_incident("/by-category", request)


@router.get("/density", dependencies=[Depends(require_permission("analytics:read"))])
async def get_top_forests(request: Request):
    return await _call_incident("/density", request)


@router.get("/peak-hours", dependencies=[Depends(require_permission("analytics:read"))])
async def get_peak_hours(request: Request):
    return await _call_incident("/peak-hours", request)