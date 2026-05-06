#!/bin/bash
set -e

echo "=== Running Local Security Scans ==="

echo "1. npm audit..."
cd backend && npm audit --audit-level=moderate || true

echo "2. Trivy filesystem scan..."
cd ..
trivy fs --severity HIGH,CRITICAL . || true

echo "3. Trivy image scan (backend)..."
docker build -t notes-backend:local .
trivy image --severity HIGH,CRITICAL notes-backend:local || true

echo "4. Trivy image scan (frontend)..."
docker build -t notes-frontend:local ./frontend
trivy image --severity HIGH,CRITICAL notes-frontend:local || true

echo "=== Security scans complete ==="
