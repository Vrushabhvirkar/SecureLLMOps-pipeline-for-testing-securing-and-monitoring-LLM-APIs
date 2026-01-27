#!/bin/bash
set -e
set -o pipefail

echo "🔍 Running Promptfoo LLM security scan..."

unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

# ❌ OLD — Promptfoo ran without runtime JWT token
# npx promptfoo eval \
#   -c ./promptfooconfig.yaml \
#   --no-cache

# ✅ NEW — Fetch a fresh JWT token before Promptfoo runs
./scanner/get_jwt_token.sh

# ❌ OLD — blindly source JWT env file
# source /tmp/jwt.env

# ✅ NEW — fail-fast if token file missing or empty
if [ ! -f /tmp/jwt.env ]; then
  echo "❌ JWT env file not found!"
  exit 1
fi

#source /tmp/jwt.env
#. /tmp/jwt.env
set -a
source /tmp/jwt.env
set +a


if [ -z "$RUNTIME_JWT_TOKEN" ]; then
  echo "❌ JWT token is empty!"
  exit 1
fi

# ✅ NEW — Run Promptfoo with live auth context
npx promptfoo eval \
  -c ./promptfooconfig.yaml \
  --no-cache

./scanner/export_promptfoo.sh
python3 ./scanner/security_gate.py

echo "✅ Security scan complete"

