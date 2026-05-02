from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.database import get_db
from app.utils.deps import require_permission
from datetime import datetime

router = APIRouter(prefix="/analytics", tags=["analytics"])

# ── 1. KPI Summary Cards ────────────────────────────────────────────────────────
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


# ── 2. Monthly Incident Trend (line chart / courbe) ──────────────────────────────
# Returns one row per month for the given year.
# Flutter renders as a LineChart with months on x-axis, incident count on y-axis.

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


# ── 3. Top 3 Agents by Incident Count ────────────────────────────────────────────
# Horizontal bar chart: agents on y-axis, incident count on x-axis.

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


# ── 4. Incidents by Category ─────────────────────────────────────────────────────
# Full pie chart.

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


# ── 5. Top 3 Forests by Incident Count ───────────────────────────────────────────
# Horizontal bar chart: forests on y-axis, incident count on x-axis.

@router.get("/density", dependencies=[Depends(require_permission("analytics:read"))])
async def get_top_forests(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("""
        SELECT
            COALESCE(forest_name, 'Hors forêt')            AS forest_name,
            COUNT(*)                                        AS total,
            COUNT(*) FILTER (WHERE status = 'resolved')    AS resolved,
            COUNT(*) FILTER (WHERE is_critical = TRUE)     AS critical
        FROM incidents
        WHERE forest_id IS NOT NULL
        GROUP BY forest_name
        ORDER BY total DESC
        LIMIT 3
    """))
    return [dict(r) for r in result.mappings().all()]

# ── 6. Peak Incident Hours ─────────────────────────────────────────────────────
# Heatmap: incident count grouped by day-of-week × hour-of-day.
# dow: 0 = Sunday … 6 = Saturday  |  hour: 0–23

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