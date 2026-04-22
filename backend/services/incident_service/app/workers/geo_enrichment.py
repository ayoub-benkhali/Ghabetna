import asyncio
import json
import logging
import httpx
import redis.asyncio as aioredis
from sqlalchemy import update
from app.config import settings
from app.database import AsyncSessionLocal
from app.models.incident import GeoEnrichmentStatus, Incident
from app.redis_client import get_redis

"""
Runs as a background asyncio task inside the incident_service process.

Loop:
  1. BRPOP "geo_enrich_queue"  (blocks until a message arrives — no busy-wait)
  2. Call forest_service /internal/parcelle-by-point?lat=&lng=
  3. UPDATE incidents SET parcelle_id=?, forest_id=? WHERE id=?
"""


logger = logging.getLogger("geo_enrichment_worker")

QUEUE_KEY = "geo_enrich_queue"
BLOCK_TIMEOUT_S = 5   # seconds to block on BRPOP before looping (allows clean shutdown)


async def _enrich_one(incident_id: int, lat: float, lng: float) -> None:
    """Fetch parcelle info from forest_service and persist it on the incident."""
    url = f"{settings.FOREST_SERVICE_URL}/parcelles/by-point"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, params={"lat": lat, "lng": lng})

        if resp.status_code == 404:
            logger.info(
                "Incident %d: point (%.6f, %.6f) not inside any parcelle — skipping.",
                incident_id, lat, lng,
            )
            async with AsyncSessionLocal() as db:
                await db.execute(
                    update(Incident)
                    .where(Incident.id == incident_id)
                    .values(geo_enrichment_status=GeoEnrichmentStatus.NOT_FOUND)
                )
                await db.commit()
            return

        resp.raise_for_status()
        data = resp.json()

        parcelle_id: int = data["parcelle_id"]
        forest_id: int = data["forest_id"]

    except Exception as exc:
        logger.error("Incident %d: forest_service lookup failed — %s", incident_id, exc)
        # Re-raise so the caller can decide whether to retry / dead-letter
        raise

    # Persist the result
    async with AsyncSessionLocal() as db:
        await db.execute(
            update(Incident)
            .where(Incident.id == incident_id)
            .values(
                parcelle_id=parcelle_id, 
                forest_id=forest_id,
                geo_enrichment_status=GeoEnrichmentStatus.ENRICHED,
                )
        )
        await db.commit()

    logger.info(
        "Incident %d enriched → parcelle_id=%d  forest_id=%d",
        incident_id, parcelle_id, forest_id,
    )


async def run_worker(stop_event: asyncio.Event) -> None:
    """
    Main worker loop. Exits cleanly when stop_event is set.
    Call this from the FastAPI lifespan as an asyncio.Task.
    """
    logger.info("Geo-enrichment worker started.")
    redis=await get_redis()

    while not stop_event.is_set():
        # BRPOP blocks for BLOCK_TIMEOUT_S seconds then returns None (timeout).
        # This keeps the loop responsive to stop_event.
        item = await redis.brpop([QUEUE_KEY], timeout=BLOCK_TIMEOUT_S)

        if item is None:
            continue   # timeout — check stop_event and loop again

        _key, raw = item
        try:
            msg = json.loads(raw)
            incident_id: int = msg["incident_id"]
            lat: float = float(msg["lat"])
            lng: float = float(msg["lng"])
        except (KeyError, ValueError, json.JSONDecodeError) as exc:
            logger.error("Malformed message — discarding: %s  error: %s", raw, exc)
            continue

        try:
            await _enrich_one(incident_id, lat, lng)
        except Exception:
            # Log and continue — a failed enrichment is non-fatal.
            # For production, push to a dead-letter list here.
            logger.exception("Enrichment failed for incident %d", incident_id)
            dead_letter_payload = json.dumps({
                "incident_id": incident_id, "lat": lat, "lng": lng
            })
            await redis.lpush("geo_enrich_dead_letter", dead_letter_payload)

    logger.info("Geo-enrichment worker stopped.")