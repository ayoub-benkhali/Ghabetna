#!/bin/sh
echo "Running seed..."
python seed.py
echo "Starting server..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload