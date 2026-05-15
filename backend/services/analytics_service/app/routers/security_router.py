from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from sqlalchemy.sql import func
from datetime import datetime, timezone, timedelta
from typing import List,Sequence

from app.database import get_db
from app.models.security import SecurityEvent, SecurityAlert, SecuritySummary, ThreatLevel
from app.schemas.security_schema import (
    SecurityEventIn, SecurityAlertIn, SecuritySummaryIn,
    SecurityAlertOut, SecuritySummaryOut,
)
from app.utils.deps import require_permission
from app.config import settings

router = APIRouter(prefix="/security", tags=["security"])


def _verify_webhook_secret(x_webhook_secret: str = Header(...)):
    """Simple shared-secret check so only n8n can write to these endpoints."""
    if x_webhook_secret != settings.SECURITY_WEBHOOK_SECRET:
        raise HTTPException(status_code=403, detail="Invalid webhook secret")


# ── n8n writes ───────────────────────────────────────────────────────────────

@router.post("/event", dependencies=[Depends(_verify_webhook_secret)], status_code=201)
async def receive_event(payload: SecurityEventIn, db: AsyncSession = Depends(get_db)):
    """n8n Workflow 1 posts every auth event here for storage."""
    event = SecurityEvent(**payload.model_dump())
    db.add(event)
    await db.commit()
    return {"status": "stored"}


@router.post("/alert", dependencies=[Depends(_verify_webhook_secret)], status_code=201)
async def receive_alert(payload: SecurityAlertIn, db: AsyncSession = Depends(get_db)):
    """n8n Workflow 1 posts a fired rule alert here."""
    alert = SecurityAlert(**payload.model_dump())
    db.add(alert)
    await db.commit()
    return {"status": "stored"}


@router.post("/summary", dependencies=[Depends(_verify_webhook_secret)], status_code=201)
async def receive_summary(payload: SecuritySummaryIn, db: AsyncSession = Depends(get_db)):
    """n8n Workflow 2 posts the Gemini-generated digest here every 30 min."""
    # Keep only the latest — delete all old summaries first
    await db.execute(delete(SecuritySummary))
    summary = SecuritySummary(**payload.model_dump())
    db.add(summary)
    await db.commit()
    return {"status": "stored"}


# ── Flutter reads ────────────────────────────────────────────────────────────

@router.get("/alerts", dependencies=[Depends(require_permission("analytics:read"))])
async def get_alerts(db: AsyncSession = Depends(get_db)) -> List[SecurityAlertOut]:
    """Returns the 10 most recent alerts (last 24h)."""
    since = datetime.now(timezone.utc) - timedelta(hours=24)
    result = await db.execute(
        select(SecurityAlert)
        .where(SecurityAlert.fired_at >= since)
        .order_by(SecurityAlert.fired_at.desc())
        .limit(10)
    )
    alerts: Sequence[SecurityAlert] = result.scalars().all()
    return [SecurityAlertOut.model_validate(a) for a in alerts]


@router.get("/summary", dependencies=[Depends(require_permission("analytics:read"))])
async def get_summary(db: AsyncSession = Depends(get_db)) -> SecuritySummaryOut:
    """Returns the latest LLM digest + current active alerts."""
    # Get latest summary
    summary_result = await db.execute(
        select(SecuritySummary).order_by(SecuritySummary.generated_at.desc()).limit(1)
    )
    summary = summary_result.scalar_one_or_none()

    # Get active alerts (last 24h, max 5 for the dashboard card)
    since = datetime.now(timezone.utc) - timedelta(hours=24)
    alerts_result = await db.execute(
        select(SecurityAlert)
        .where(SecurityAlert.fired_at >= since)
        .order_by(SecurityAlert.fired_at.desc())
        .limit(5)
    )
    alerts = alerts_result.scalars().all()

    # Derive threat level from alerts if no summary exists yet
    if not summary:
        if any(a.severity == ThreatLevel.high for a in alerts):
            level = ThreatLevel.high
        elif alerts:
            level = ThreatLevel.medium
        else:
            level = ThreatLevel.low

        return SecuritySummaryOut(
            threat_level=level,
            summary_text="No AI digest generated yet. Check back after the first scheduled analysis.",
            generated_at=datetime.now(timezone.utc),
            active_alerts=[SecurityAlertOut.model_validate(a) for a in alerts],
        )

    return SecuritySummaryOut.model_validate({
    "threat_level": summary.threat_level,
    "summary_text": summary.summary_text,
    "generated_at": summary.generated_at,
    "active_alerts": [SecurityAlertOut.model_validate(a) for a in alerts],
    })


@router.get("/events/recent", dependencies=[Depends(_verify_webhook_secret)])
async def get_recent_events(db: AsyncSession = Depends(get_db)):
    """
    n8n Workflow 2 calls this to get the last 30 min of events AND alerts
    before sending them to Groq for summarization.
    """
    since = datetime.now(timezone.utc) - timedelta(minutes=30)

    # ── Raw events ───────────────────────────────────────────────────────────
    events_result = await db.execute(
        select(SecurityEvent)
        .where(SecurityEvent.timestamp >= since)
        .order_by(SecurityEvent.timestamp.desc())
    )
    events = events_result.scalars().all()

    # ── Fired alerts ─────────────────────────────────────────────────────────
    alerts_result = await db.execute(
        select(SecurityAlert)
        .where(SecurityAlert.fired_at >= since)
        .order_by(SecurityAlert.fired_at.desc())
    )
    alerts = alerts_result.scalars().all()

    return {
        "events": [
            {
                "event": e.event,
                "email": e.email,
                "role": e.role,
                "ip": e.ip,
                "failed_attempts": e.failed_attempts,
                "timestamp": e.timestamp.isoformat(),
            }
            for e in events
        ],
        "alerts": [
            {
                "type": a.alert_type,
                "severity": a.severity,
                "email": a.email,
                "ip": a.ip,
                "detail": a.detail,
                "fired_at": a.fired_at.isoformat(),
            }
            for a in alerts
        ],
    }