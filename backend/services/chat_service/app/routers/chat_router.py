from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.chat_schema import (
    ChatMessage,
    ChatResponse,
    ConversationSummary,
    ConversationDetail,
    MessageOut,
)
from app.services import chat_service
from app.utils.deps import get_current_user_payload

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/message", response_model=ChatResponse)
async def send_message(
    body: ChatMessage,
    db: AsyncSession = Depends(get_db),
    payload: dict = Depends(get_current_user_payload)
):
    try:
        user_id = int(payload["sub"])
        result = await chat_service.process_chat(
            db=db,
            message=body.message,
            session_id=body.session_id,
            user_id=user_id
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/conversations", response_model=list[ConversationSummary])
async def get_conversations(
    db: AsyncSession = Depends(get_db),
    payload: dict = Depends(get_current_user_payload)
):
    user_id = int(payload["sub"])
    return await chat_service.list_conversations(db, user_id)


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(
    conversation_id: str,
    db: AsyncSession = Depends(get_db),
    payload: dict = Depends(get_current_user_payload)
):
    user_id = int(payload["sub"])
    conversation = await chat_service.get_conversation(db, conversation_id, user_id)
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversation introuvable")
    return {
        "id": conversation.id,
        "title": conversation.title or "Nouvelle conversation",
        "messages": [MessageOut.model_validate(m) for m in conversation.messages],
    }


@router.delete("/conversations/{conversation_id}")
async def remove_conversation(
    conversation_id: str,
    db: AsyncSession = Depends(get_db),
    payload: dict = Depends(get_current_user_payload)
):
    user_id = int(payload["sub"])
    deleted = await chat_service.delete_conversation(db, conversation_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Conversation introuvable")
    return {"message": "Conversation supprimée"}


# Conservé pour compatibilité: équivalent à la suppression de la conversation
@router.delete("/session/{session_id}")
async def clear_session(
    session_id: str,
    db: AsyncSession = Depends(get_db),
    payload: dict = Depends(get_current_user_payload)
):
    user_id = int(payload["sub"])
    await chat_service.delete_conversation(db, session_id, user_id)
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
