from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.database import get_db
from app.utils.deps import require_permission
from datetime import date
from typing import Optional

router = APIRouter(prefix="/analytics", tags=["analytics"])

# ── 1. KPI Summary Cards ────────────────────────────────────────────────────────
# Returns the 4 top-level numbers for the admin dashboard cards:
# total incidents, critical count, resolved count, pending count

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


# ── 2. Incidents per Day (last N days) ──────────────────────────────────────────
# Used for the line/bar chart showing daily volume, split critical vs non-critical

@router.get("/daily", dependencies=[Depends(require_permission("analytics:read"))])
async def get_daily_trend(
    days: int = Query(default=30, ge=7, le=365),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(text("""
        SELECT
            DATE(created_at)                                    AS day,
            COUNT(*)                                            AS total,
            COUNT(*) FILTER (WHERE is_critical = TRUE)         AS critical,
            COUNT(*) FILTER (WHERE status = 'resolved')        AS resolved
        FROM incidents
        WHERE created_at >= NOW() - INTERVAL '1 day' * :days
        GROUP BY DATE(created_at)
        ORDER BY day ASC
    """), {"days": days})
    return [dict(r) for r in result.mappings().all()]


# ── 3. Incidents by Forest ───────────────────────────────────────────────────────
# Table/bar chart: per forest, how many total / critical / resolved
# forest_id=NULL means incident was reported outside any known forest boundary

@router.get("/by-forest", dependencies=[Depends(require_permission("analytics:read"))])
async def get_by_forest(
    month: Optional[int] = Query(default=None, ge=1, le=12),
    year: Optional[int] = Query(default=None, ge=2020),
    db: AsyncSession = Depends(get_db),
):
    where_clause = ""
    params: dict = {}
    if month and year:
        where_clause = "WHERE EXTRACT(MONTH FROM created_at) = :month AND EXTRACT(YEAR FROM created_at) = :year"
        params = {"month": month, "year": year}

    result = await db.execute(text(f"""
        SELECT
            COALESCE(forest_id::text, 'unknown')               AS forest_id,
            COUNT(*)                                           AS total,
            COUNT(*) FILTER (WHERE is_critical = TRUE)        AS critical,
            COUNT(*) FILTER (WHERE status = 'resolved')       AS resolved,
            COUNT(*) FILTER (WHERE status = 'pending')        AS pending
        FROM incidents
        {where_clause}
        GROUP BY forest_id
        ORDER BY total DESC
    """), params)
    return [dict(r) for r in result.mappings().all()]


# ── 4. Incidents by Category ─────────────────────────────────────────────────────
# Donut/pie chart: feu, coupe_illegale, refuge_suspect, etc.

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


# ── 5. Status Breakdown per Forest per Month ─────────────────────────────────────
# The "inspection dashboard" table: rows=forests, columns=treated/untreated/critical

@router.get("/inspection", dependencies=[Depends(require_permission("analytics:read"))])
async def get_inspection_table(
    year: int = Query(default=2026),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(text("""
        SELECT
            COALESCE(forest_id::text, 'unknown')              AS forest_id,
            EXTRACT(MONTH FROM created_at)::int               AS month,
            COUNT(*)                                          AS total,
            COUNT(*) FILTER (WHERE status = 'resolved')      AS treated,
            COUNT(*) FILTER (WHERE status != 'resolved')     AS untreated,
            COUNT(*) FILTER (WHERE is_critical = TRUE)       AS critical
        FROM incidents
        WHERE EXTRACT(YEAR FROM created_at) = :year
        GROUP BY forest_id, EXTRACT(MONTH FROM created_at)
        ORDER BY forest_id, month
    """), {"year": year})
    return [dict(r) for r in result.mappings().all()]