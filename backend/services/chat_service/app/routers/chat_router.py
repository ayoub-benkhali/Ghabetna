from fastapi import APIRouter, Depends, HTTPException
from app.schemas.chat_schema import ChatMessage, ChatResponse
from app.services.chat_service import process_chat
from app.utils.deps import get_current_user_payload

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("/message", response_model=ChatResponse)
async def send_message(
    body: ChatMessage,
    payload: dict = Depends(get_current_user_payload)
):
    try:
        user_id = int(payload["sub"])
        result = await process_chat(
            message=body.message,
            session_id=body.session_id,
            user_id=user_id
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/session/{session_id}")
async def clear_session(
    session_id: str,
    payload: dict = Depends(get_current_user_payload)
):
    from app.services.chat_service import session_store
    if session_id in session_store:
        del session_store[session_id]
    return {"message": "Session cleared"}

@router.get("/health")
async def health():
    from app.services.rag_service import rag_service
    doc_count = rag_service.collection.count() if rag_service.collection else 0
    return {
        "status": "ok",
        "service": "chat-service",
        "rag_documents": doc_count
    }