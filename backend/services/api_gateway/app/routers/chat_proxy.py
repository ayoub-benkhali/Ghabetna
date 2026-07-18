import httpx
from fastapi import APIRouter, Request, Response
from app.config import settings

router = APIRouter(prefix="/api/chat", tags=["Chat"])

async def _proxy(path: str, request: Request) -> Response:
    body = await request.body()
    headers = {
        "Content-Type": request.headers.get("Content-Type", "application/json"),
        "Authorization": request.headers.get("Authorization", ""),
    }
    async with httpx.AsyncClient(base_url=settings.CHAT_SERVICE_URL) as client:
        resp = await client.request(
            method=request.method,
            url=f"/chat{path}",
            content=body,
            headers=headers,
            timeout=30.0,
        )
    return Response(
        content=resp.content,
        status_code=resp.status_code,
        media_type=resp.headers.get("content-type")
    )

@router.post("/message")
async def send_message(request: Request):
    return await _proxy("/message", request)

@router.delete("/session/{session_id}")
async def clear_session(session_id: str, request: Request):
    return await _proxy(f"/session/{session_id}", request)

@router.get("/health")
async def health(request: Request):
    return await _proxy("/health", request)