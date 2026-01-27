#!/bin/bash
set -e

echo "[+] Fetching runtime JWT token..."

LOGIN_RESPONSE=$(curl -s -X POST http://127.0.0.1:8000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"pass123"}')

echo "[DEBUG] Login response: $LOGIN_RESPONSE"

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token')

# ❌ OLD — silent failure
# export RUNTIME_JWT_TOKEN="$TOKEN"
# echo "RUNTIME_JWT_TOKEN=$TOKEN" > /tmp/jwt.env

# ✅ NEW — fail fast + correct export
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Failed to extract JWT token"
  exit 1
fi

export RUNTIME_JWT_TOKEN="$TOKEN"

echo "RUNTIME_JWT_TOKEN=$TOKEN" > /tmp/jwt.env

echo "✅ Token fetched and stored"

