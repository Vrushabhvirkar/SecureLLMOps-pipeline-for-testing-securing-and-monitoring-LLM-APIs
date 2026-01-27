#!/bin/bash
set -e

echo "🚀 Starting LLM Security Pipeline..."

# 1️⃣ Build image
echo "[1] Building llm-api image..."
docker build -t llm-api -f docker/Dockerfile .

# 2️⃣ Run API container
echo "[2] Starting API container..."
docker rm -f llm-api-container >/dev/null 2>&1 || true

API_PORT=8010

# ❌ OLD — no secrets passed into container
# docker run -d -p $API_PORT:8000 --name llm-api-container llm-api

# ✅ NEW — hard inject secrets so JWT works inside Docker
docker run -d -p $API_PORT:8000 \
  -e APP_API_KEY="mysecureapikey123" \
  -e JWT_SECRET="jwt-9aD!xP9Lq#k2304" \
  --name llm-api-container \
  llm-api

# Wait for API
#echo "⏳ Waiting for API to be ready..."
#sleep 5
echo "⏳ Waiting for API to be ready..."

for i in {1..20}; do
  if curl -s http://127.0.0.1:$API_PORT/health >/dev/null; then
    echo "✅ API is ready"
    break
  fi
  echo "⏳ API not ready yet... ($i)"
  sleep 2
done

# 3️⃣ Run Promptfoo scan
echo "[3] Running Promptfoo LLM scan..."
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

# ❌ OLD — does not reload runtime JWT
# npx promptfoo eval -c promptfooconfig.yaml --no-cache
# npx promptfoo eval -c promptfooconfig.yaml --no-cache || echo "⚠️ Promptfoo reported failures, continuing to export..."

# ✅ NEW — fetch fresh JWT, then load it
echo "[+] Fetching runtime JWT token..."
./scanner/get_jwt_token.sh

# ✅ NEW — reload JWT into env right before Promptfoo
set -a
source /tmp/jwt.env
set +a

echo "DEBUG PIPELINE: RUNTIME_JWT_TOKEN=$RUNTIME_JWT_TOKEN"
echo "DEBUG PIPELINE: APP_API_KEY=$APP_API_KEY"

npx promptfoo eval -c promptfooconfig.yaml --no-cache || echo "⚠️ Promptfoo reported failures, continuing to export..."

# 4️⃣ Export results
echo "[4] Exporting results..."
./scanner/export_promptfoo.sh

PIPELINE_FAILED=0

echo "[5] Running security gate..."
if ! python3 scanner/security_gate.py; then
  echo "❌ Security gate failed"
  PIPELINE_FAILED=1
fi

echo "[6] Running Trivy container scan..."
if ! ./scanner/run_trivy_scan.sh; then
  echo "❌ Trivy scan failed"
  PIPELINE_FAILED=1
fi

if [ "$PIPELINE_FAILED" -ne 0 ]; then
  echo "❌ Pipeline failed due to security issues"
  exit 1
fi

echo "✅ Pipeline complete."

