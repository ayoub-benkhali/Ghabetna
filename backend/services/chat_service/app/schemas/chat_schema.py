from datetime import datetime
from pydantic import BaseModel
from typing import Optional

class ChatMessage(BaseModel):
    message: str
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    session_id: str
    language: str
    sources: list[str] = []

class ConversationSummary(BaseModel):
    id: str
    title: str
    last_message: str
    updated_at: datetime

    class Config:
        from_attributes = True

class MessageOut(BaseModel):
    role: str
    content: str
    created_at: datetime

    class Config:
        from_attributes = True

class ConversationDetail(BaseModel):
    id: str
    title: str
    messages: list[MessageOut]