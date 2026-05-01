import httpx
from fastapi import APIRouter, Request, Response
from app.config import settings

router = APIRouter(prefix="/analytics", tags=["analytics"])

async def _forward(request: Request, path: str) -> Response:
    url = f"{settings.ANALYTICS_SERVICE_URL}/analytics{path}"
    params = dict(request.query_params)
    headers = {"Authorization": request.headers.get("Authorization", "")}
    async with httpx.AsyncClient() as client:
        r = await client.get(url, params=params, headers=headers, timeout=15)
    return Response(content=r.content, status_code=r.status_code,
                    media_type="application/json")

@router.get("/kpis")
async def kpis(request: Request): return await _forward(request, "/kpis")

@router.get("/daily")
async def daily(request: Request): return await _forward(request, "/daily")

@router.get("/by-forest")
async def by_forest(request: Request): return await _forward(request, "/by-forest")

@router.get("/by-category")
async def by_category(request: Request): return await _forward(request, "/by-category")

@router.get("/inspection")
async def inspection(request: Request): return await _forward(request, "/inspection")