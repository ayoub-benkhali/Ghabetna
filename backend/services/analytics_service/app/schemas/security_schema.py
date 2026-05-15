from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from app.models.security import ThreatLevel

# ── Incoming from n8n ────────────────────────────────────────────────────────

class SecurityEventIn(BaseModel):
    event: str
    email: str
    role: str
    ip: str
    failed_attempts: int = 0
    timestamp: datetime

class SecurityAlertIn(BaseModel):
    alert_type: str
    severity: ThreatLevel
    ip: Optional[str] = None
    email: Optional[str] = None
    detail: Optional[str] = None

class SecuritySummaryIn(BaseModel):
    threat_level: ThreatLevel
    summary_text: str

# ── Outgoing to Flutter ──────────────────────────────────────────────────────

class SecurityAlertOut(BaseModel):
    id: int
    alert_type: str
    severity: ThreatLevel
    ip: Optional[str]
    email: Optional[str]
    detail: Optional[str]
    fired_at: datetime

    class Config:
        from_attributes = True

class SecuritySummaryOut(BaseModel):
    threat_level: ThreatLevel
    summary_text: str
    generated_at: datetime
    active_alerts: List[SecurityAlertOut]

    class Config:
        from_attributes = True