import uuid
import logging
from datetime import datetime, timezone

from groq import Groq
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.services.rag_service import rag_service
from app.models.conversation import Conversation, Message

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """Tu es GhabetnaBot, un assistant intelligent et bienveillant de la plateforme Ghabetna — une application tunisienne de surveillance et signalement des incidents forestiers.

Tes missions :
1. Guider les visiteurs dans l'utilisation de l'application Ghabetna
2. Répondre aux questions sur les forêts tunisiennes et leur protection
3. Aider à comprendre comment signaler un incident correctement
4. Informer sur les règles à respecter en forêt

RÈGLE ABSOLUE SUR LA LANGUE :
- Si la question contient des mots arabes ou est écrite en arabe → réponds OBLIGATOIREMENT et ENTIÈREMENT en arabe, sans aucun mot français
- Si la question est en français → réponds entièrement en français
- Si le visiteur mélange français et arabe (darija) → réponds en français
- Ne mélange JAMAIS les deux langues dans une même réponse

Règles importantes :
- Sois concis, clair et bienveillant
- Si tu ne sais pas quelque chose, dis-le honnêtement
- Ne réponds qu'aux questions liées à Ghabetna, aux forêts et à l'environnement
- Pour toute urgence (incendie actif, danger immédiat), recommande d'appeler le 1800 (numéro protection civile Tunisie)

Contexte de l'application :
- Les visiteurs peuvent signaler des incidents : feu, coupe illégale, déchets, maladie végétale, trafic, refuge suspect
- Après connexion, le visiteur accède à : Signaler un incident, Mes signalements, Mon profil
- Les incidents sont traités par des agents et superviseurs professionnels
"""


def detect_language(text: str) -> str:
    arabic_chars = sum(1 for c in text if '\u0600' <= c <= '\u06FF')
    if arabic_chars > len(text) * 0.2:
        return "ar"
    return "fr"


def build_context_prompt(rag_docs: list[str]) -> str:
    if not rag_docs:
        return ""
    context = "\n\n".join(rag_docs)
    return f"""
Voici des informations pertinentes de la base de connaissances Ghabetna pour répondre à cette question :

{context}

Utilise ces informations pour répondre de façon précise et personnalisée.
"""


def _make_title(first_message: str) -> str:
    title = first_message.strip().replace("\n", " ")
    return (title[:47] + "...") if len(title) > 50 else title


async def _get_owned_conversation(db: AsyncSession, conversation_id: str, user_id: int) -> Conversation | None:
    result = await db.execute(
        select(Conversation).where(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()


async def process_chat(
    db: AsyncSession,
    message: str,
    session_id: str | None,
    user_id: int
) -> dict:
    conversation: Conversation | None = None

    if session_id:
        conversation = await _get_owned_conversation(db, session_id, user_id)

    if conversation is None:
        conversation = Conversation(id=session_id or str(uuid.uuid4()), user_id=user_id)
        db.add(conversation)
        await db.flush()

    # Historique existant de CETTE conversation (max 10 derniers échanges)
    history_rows = conversation.messages[-20:]
    history = [{"role": m.role, "content": m.content} for m in history_rows]

    # Détecter la langue
    language = detect_language(message)

    # Chercher dans la base RAG
    rag_docs = rag_service.search(message, n_results=3)
    context_prompt = build_context_prompt(rag_docs)

    # Construire les messages
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]

    if context_prompt:
        messages.append({"role": "system", "content": context_prompt})

    messages.extend(history[-10:])
    messages.append({"role": "user", "content": message})

    # Appel Groq
    client = Groq(api_key=settings.GROQ_API_KEY)
    response = client.chat.completions.create(
        model="llama-3.1-8b-instant",
        messages=messages,
        max_tokens=1024,
        temperature=0.7,
    )

    assistant_message = response.choices[0].message.content

    # Persister les 2 nouveaux messages
    db.add(Message(conversation_id=conversation.id, role="user", content=message))
    db.add(Message(conversation_id=conversation.id, role="assistant", content=assistant_message))

    if conversation.title is None:
        conversation.title = _make_title(message)

    conversation.updated_at = datetime.now(timezone.utc)

    await db.commit()

    return {
        "response": assistant_message,
        "session_id": conversation.id,
        "language": language,
        "sources": [doc[:100] + "..." for doc in rag_docs] if rag_docs else []
    }


async def list_conversations(db: AsyncSession, user_id: int) -> list[dict]:
    result = await db.execute(
        select(Conversation)
        .where(Conversation.user_id == user_id)
        .order_by(Conversation.updated_at.desc())
    )
    conversations = result.scalars().all()

    summaries = []
    for c in conversations:
        last = c.messages[-1] if c.messages else None
        summaries.append({
            "id": c.id,
            "title": c.title or "Nouvelle conversation",
            "last_message": (last.content[:80] + "...") if last and len(last.content) > 80 else (last.content if last else ""),
            "updated_at": c.updated_at,
        })
    return summaries


async def get_conversation(db: AsyncSession, conversation_id: str, user_id: int) -> Conversation | None:
    return await _get_owned_conversation(db, conversation_id, user_id)


async def delete_conversation(db: AsyncSession, conversation_id: str, user_id: int) -> bool:
    conversation = await _get_owned_conversation(db, conversation_id, user_id)
    if conversation is None:
        return False
    await db.execute(delete(Conversation).where(Conversation.id == conversation_id))
    await db.commit()
    return True
