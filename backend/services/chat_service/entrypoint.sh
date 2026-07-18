#!/bin/sh
echo "Initializing RAG documents..."
python init_rag.py
echo "Starting chat service..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload