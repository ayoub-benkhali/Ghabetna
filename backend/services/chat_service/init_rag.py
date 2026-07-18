"""
Script d'initialisation RAG — lancé au démarrage du service.
Charge les documents depuis /app/documents/ et les vectorise dans ChromaDB.
"""
import os
import logging
from app.services.rag_service import rag_service
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DOCUMENTS_DIR = "/app/documents"

def load_documents_from_dir(directory: str) -> list[dict]:
    documents = []
    if not os.path.exists(directory):
        logger.warning(f"Documents directory not found: {directory}")
        return documents

    for filename in os.listdir(directory):
        if filename.endswith(".md") or filename.endswith(".txt"):
            filepath = os.path.join(directory, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            # Découper en chunks de ~500 caractères
            chunks = split_into_chunks(content, chunk_size=500, overlap=50)
            for i, chunk in enumerate(chunks):
                documents.append({
                    "id": f"{filename}_{i}",
                    "text": chunk,
                    "metadata": {
                        "source": filename,
                        "chunk_index": i
                    }
                })
            logger.info(f"Loaded {len(chunks)} chunks from {filename}")

    return documents

def split_into_chunks(text: str, chunk_size: int = 500, overlap: int = 50) -> list[str]:
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        if chunk.strip():
            chunks.append(chunk.strip())
        start = end - overlap
    return chunks

def main():
    logger.info("Starting RAG initialization...")
    rag_service.initialize()

    existing_count = rag_service.collection.count()
    if existing_count > 0:
        logger.info(f"RAG already initialized with {existing_count} documents — skipping")
        return

    documents = load_documents_from_dir(DOCUMENTS_DIR)
    if not documents:
        logger.warning("No documents found — RAG will work without context")
        return

    rag_service.add_documents(documents)
    logger.info(f"RAG initialized with {len(documents)} chunks total")

if __name__ == "__main__":
    main()