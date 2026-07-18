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