import httpx
import logging
from datetime import datetime, timezone
from app.config import settings

logger = logging.getLogger(__name__)

async def emit_security_event(
    event: str, # "login_success" | "login_failed" | "admin_action" etc.
    email: str,
    role: str,
    ip: str,
    failed_attempts: int = 0,
) -> None:
    """Fire-and-forget POST to the n8n security webhook."""
    payload = {
        "event": event,
        "email": email,
        "role": role,
        "ip": ip,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "failed_attempts": failed_attempts,
    }
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            await client.post(settings.N8N_WEBHOOK_URL, json=payload)
    except Exception as e:
        # Never let the security webhook crash the login flow
        logger.warning(f"[security_events] Failed to emit event: {e}")