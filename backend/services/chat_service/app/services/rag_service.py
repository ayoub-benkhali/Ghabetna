import chromadb
from app.config import settings
import logging

logger = logging.getLogger(__name__)

class RAGService:
    def __init__(self):
        self.client = None
        self.collection = None

    def initialize(self):
        try:
            self.client = chromadb.PersistentClient(
                path=settings.CHROMA_PERSIST_DIR
            )
            self.collection = self.client.get_or_create_collection(
                name="ghabetna_docs",
                metadata={"hnsw:space": "cosine"}
            )
            logger.info(f"RAG initialized — {self.collection.count()} documents in collection")
        except Exception as e:
            logger.error(f"RAG initialization error: {e}")
            raise

    def search(self, query: str, n_results: int = 3) -> list[str]:
        if not self.collection:
            return []
        try:
            count = self.collection.count()
            if count == 0:
                return []
            results = self.collection.query(
                query_texts=[query],
                n_results=min(n_results, count)
            )
            documents = results.get("documents", [[]])[0]
            return documents
        except Exception as e:
            logger.error(f"RAG search error: {e}")
            return []

    def add_documents(self, documents: list[dict]):
        if not self.collection:
            return
        ids = [doc["id"] for doc in documents]
        texts = [doc["text"] for doc in documents]
        metadatas = [doc.get("metadata", {}) for doc in documents]
        self.collection.upsert(
            ids=ids,
            documents=texts,
            metadatas=metadatas
        )
        logger.info(f"Added {len(documents)} documents to RAG")

rag_service = RAGService()