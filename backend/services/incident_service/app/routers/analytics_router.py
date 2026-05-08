from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.database import get_db
from app.utils.deps import require_permission
from datetime import datetime

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/kpis", dependencies=[Depends(require_permission("analytics:read"))])
async def get_kpis(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            COUNT(*)                                        AS total,
            COUNT(*) FILTER (WHERE is_critical = TRUE)     AS critical,
            COUNT(*) FILTER (WHERE status = 'resolved')    AS resolved,
            COUNT(*) FILTER (WHERE status = 'pending')     AS pending
        FROM incidents
    """))
    row = result.mappings().one()
    return dict(row)


@router.get("/daily", dependencies=[Depends(require_permission("analytics:read"))])
async def get_monthly_trend(
    year: int = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    effective_year = year or datetime.utcnow().year
    result = await db.execute(text("""
        SELECT
            EXTRACT(MONTH FROM created_at)::int             AS month,
            COUNT(*)                                        AS total,
            COUNT(*) FILTER (WHERE is_critical = TRUE)      AS critical,
            COUNT(*) FILTER (WHERE status = 'resolved')     AS resolved
        FROM incidents
        WHERE EXTRACT(YEAR FROM created_at) = :year
        GROUP BY EXTRACT(MONTH FROM created_at)
        ORDER BY month ASC
    """), {"year": effective_year})
    return [dict(r) for r in result.mappings().all()]


@router.get("/top-agents", dependencies=[Depends(require_permission("analytics:read"))])
async def get_top_agents(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            agent_name,
            COUNT(*)                                        AS total,
            COUNT(*) FILTER (WHERE is_critical = TRUE)     AS critical,
            COUNT(*) FILTER (WHERE status = 'resolved')    AS resolved
        FROM incidents
        GROUP BY agent_name
        ORDER BY total DESC
        LIMIT 3
    """))
    return [dict(r) for r in result.mappings().all()]


@router.get("/by-category", dependencies=[Depends(require_permission("analytics:read"))])
async def get_by_category(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            category,
            COUNT(*)                                          AS total,
            COUNT(*) FILTER (WHERE is_critical = TRUE)       AS critical
        FROM incidents
        GROUP BY category
        ORDER BY total DESC
    """))
    return [dict(r) for r in result.mappings().all()]


@router.get("/density", dependencies=[Depends(require_permission("analytics:read"))])
async def get_top_forests(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            forest_id,
            COALESCE(MAX(forest_name), 'Forêt #' || forest_id::text)  AS forest_name,
            COUNT(*)                                                     AS total,
            COUNT(*) FILTER (WHERE status = 'resolved')                 AS resolved,
            COUNT(*) FILTER (WHERE is_critical = TRUE)                  AS critical
        FROM incidents
        WHERE forest_id IS NOT NULL
        GROUP BY forest_id
        ORDER BY total DESC
        LIMIT 3
    """))
    return [dict(r) for r in result.mappings().all()]


@router.get("/peak-hours", dependencies=[Depends(require_permission("analytics:read"))])
async def get_peak_hours(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            EXTRACT(DOW  FROM created_at)::int   AS dow,
            EXTRACT(HOUR FROM created_at)::int   AS hour,
            COUNT(*)                             AS total
        FROM incidents
        GROUP BY dow, hour
        ORDER BY dow, hour
    """))
    return [dict(r) for r in result.mappings().all()]