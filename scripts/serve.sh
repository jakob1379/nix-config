#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${ENVIRONMENT:-development}"

if [[ "$ENVIRONMENT" == "production" ]]; then
  echo "Starting application in production mode via python http.server"
else
  echo "Starting application in development mode with live reload"
fi

exec python3 -m http.server 8000 --bind 0.0.0.0
