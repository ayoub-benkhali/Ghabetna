from sqlalchemy import Column, Integer, String, DateTime, Text, Enum as SAEnum
from sqlalchemy.sql import func
from app.database import Base
import enum

class ThreatLevel(str, enum.Enum):
    low    = "low"
    medium = "medium"
    high   = "high"

class SecurityEvent(Base):
    """Raw login events received from auth_service via n8n."""
    __tablename__ = "security_events"

    id             = Column(Integer, primary_key=True, index=True)
    event          = Column(String(64), nullable=False)   # "login_failed", "login_success", etc.
    email          = Column(String(255), nullable=False)
    role           = Column(String(64), nullable=False)
    ip             = Column(String(64), nullable=False)
    failed_attempts= Column(Integer, default=0)
    timestamp      = Column(DateTime(timezone=True), nullable=False)
    received_at    = Column(DateTime(timezone=True), server_default=func.now())

class SecurityAlert(Base):
    """Alerts fired by n8n rules — one row per detected threat."""
    __tablename__ = "security_alerts"

    id           = Column(Integer, primary_key=True, index=True)
    alert_type   = Column(String(64), nullable=False)   # "brute_force", "off_hours_login", etc.
    severity     = Column(SAEnum(ThreatLevel), nullable=False)
    ip           = Column(String(64), nullable=True)
    email        = Column(String(255), nullable=True)
    detail       = Column(Text, nullable=True)           # human-readable: "12 attempts in 8 min"
    fired_at     = Column(DateTime(timezone=True), server_default=func.now())

class SecuritySummary(Base):
    """Latest LLM-generated digest. We only keep the most recent row."""
    __tablename__ = "security_summary"

    id           = Column(Integer, primary_key=True, index=True)
    threat_level = Column(SAEnum(ThreatLevel), nullable=False)
    summary_text = Column(Text, nullable=False)
    generated_at = Column(DateTime(timezone=True), server_default=func.now())