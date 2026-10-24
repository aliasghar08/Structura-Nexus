#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "=========================================================="
echo " Starting Structura Nexus / Structura Forge AI Engine"
echo " Standards: AISC 360-16 | ACI 318-19 | ASCE 7-16"
echo " Host: 0.0.0.0:8000 | WebSockets: /ws/structural-graph"
echo "=========================================================="

PYTHONPATH=. ./.venv/bin/uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
