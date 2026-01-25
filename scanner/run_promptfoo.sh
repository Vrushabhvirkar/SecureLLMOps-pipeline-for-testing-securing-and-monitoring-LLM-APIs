#!/bin/bash
set -e

echo "🔍 Running Promptfoo LLM security scan..."

unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy

npx promptfoo eval \
  -c ./promptfooconfig.yaml \
  --no-cache

echo "✅ Promptfoo scan complete"

