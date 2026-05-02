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
  2. Call forest_service /parcelles/by-point?lat=&lng=
  3. UPDATE incidents SET parcelle_id=?, forest_id=? WHERE id=?

The /by-point endpoint now returns a 200 even when the point is inside a
forest but not inside any specific parcelle — in that case parcelle_id is
null in the response.  We handle both cases:
  - forest + parcelle match  → enriched with both ids
  - forest-only match        → enriched with forest_id, parcelle_id stays NULL
  - 404                      → point is outside every registered forest → NOT_FOUND
"""


logger = logging.getLogger("geo_enrichment_worker")

QUEUE_KEY = "geo_enrich_queue"
BLOCK_TIMEOUT_S = 5   # seconds to block on BRPOP before looping (allows clean shutdown)


async def _enrich_one(incident_id: int, lat: float, lng: float) -> None:
    """Fetch forest/parcelle info from forest_service and persist it on the incident."""
    url = f"{settings.FOREST_SERVICE_URL}/parcelles/by-point"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, params={"lat": lat, "lng": lng})

        if resp.status_code == 404:
            # Point is outside every registered forest.
            logger.info(
                "Incident %d: point (%.6f, %.6f) not inside any forest — marking NOT_FOUND.",
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

        forest_id: int = data["forest_id"]
        forest_name: str | None = data.get("forest_name")
        # parcelle_id is optional — the endpoint returns null when the point
        # is inside a forest but not inside any drawn parcelle.
        parcelle_id: int | None = data.get("parcelle_id")

    except Exception as exc:
        logger.error("Incident %d: forest_service lookup failed — %s", incident_id, exc)
        # Re-raise so the caller can push to dead-letter queue.
        raise

    # Persist the result.  parcelle_id may be None — that is valid and means
    # "inside a forest, but no specific parcelle matched."
    async with AsyncSessionLocal() as db:
        await db.execute(
            update(Incident)
            .where(Incident.id == incident_id)
            .values(
                forest_id=forest_id,
                forest_name=data.get("forest_name"),
                parcelle_id=parcelle_id,
                geo_enrichment_status=GeoEnrichmentStatus.ENRICHED,
            )
        )
        await db.commit()

    if parcelle_id is not None:
        logger.info(
            "Incident %d enriched → forest_id=%d  parcelle_id=%d",
            incident_id, forest_id, parcelle_id,
        )
    else:
        logger.info(
            "Incident %d enriched → forest_id=%d  (no parcelle match)",
            incident_id, forest_id,
        )


async def run_worker(stop_event: asyncio.Event) -> None:
    """
    Main worker loop. Exits cleanly when stop_event is set.
    Call this from the FastAPI lifespan as an asyncio.Task.
    """
    logger.info("Geo-enrichment worker started.")
    redis = await get_redis()

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
            logger.exception("Enrichment failed for incident %d", incident_id)
            dead_letter_payload = json.dumps({
                "incident_id": incident_id, "lat": lat, "lng": lng
            })
            await redis.lpush("geo_enrich_dead_letter", dead_letter_payload)

    logger.info("Geo-enrichment worker stopped.")