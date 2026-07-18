import uuid
import logging
from groq import Groq
from app.config import settings
from app.services.rag_service import rag_service

logger = logging.getLogger(__name__)

# Session history stockée en mémoire (Redis en phase 2)
session_store: dict[str, list[dict]] = {}

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

async def process_chat(
    message: str,
    session_id: str | None,
    user_id: int
) -> dict:
    # Générer ou récupérer session
    if not session_id:
        session_id = str(uuid.uuid4())

    if session_id not in session_store:
        session_store[session_id] = []

    history = session_store[session_id]

    # Détecter la langue
    language = detect_language(message)

    # Chercher dans la base RAG
    rag_docs = rag_service.search(message, n_results=3)
    context_prompt = build_context_prompt(rag_docs)

    # Construire les messages
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT}
    ]

    # Ajouter le contexte RAG si disponible
    if context_prompt:
        messages.append({
            "role": "system",
            "content": context_prompt
        })

    # Ajouter l'historique (max 10 derniers échanges)
    messages.extend(history[-10:])

    # Ajouter le message actuel
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

    # Sauvegarder dans l'historique
    history.append({"role": "user", "content": message})
    history.append({"role": "assistant", "content": assistant_message})

    # Garder max 20 messages en mémoire
    if len(history) > 20:
        session_store[session_id] = history[-20:]

    return {
        "response": assistant_message,
        "session_id": session_id,
        "language": language,
        "sources": [doc[:100] + "..." for doc in rag_docs] if rag_docs else []
    }