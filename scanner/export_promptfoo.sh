#!/bin/bash
set -e

LATEST_EVAL=$(ls -t ~/.promptfoo/db/*.json 2>/dev/null | head -n 1 || true)

if [ -z "$LATEST_EVAL" ]; then
  echo "❌ No Promptfoo eval JSON found"
  exit 1
fi

cp "$LATEST_EVAL" reports/promptfoo-results.json

echo "📦 Exported results to reports/promptfoo-results.json"

