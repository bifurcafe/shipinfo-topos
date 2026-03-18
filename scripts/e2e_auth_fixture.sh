#!/usr/bin/env bash
set -euo pipefail

PORT="${FIXTURE_PORT:-18090}"
TOKEN="${FIXTURE_TOKEN:-fixture_test_key}"
LOG_FILE="$(mktemp)"

cleanup() {
  if [[ -n "${FIX_PID:-}" ]] && kill -0 "$FIX_PID" >/dev/null 2>&1; then
    kill "$FIX_PID" >/dev/null 2>&1 || true
    wait "$FIX_PID" >/dev/null 2>&1 || true
  fi
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

python3 shipinfo-agent-kit/scripts/run_auth_fixture_server.py >"$LOG_FILE" 2>&1 &
FIX_PID=$!

for _ in $(seq 1 30); do
  if curl -sS "http://127.0.0.1:${PORT}/v1/ping" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if ! kill -0 "$FIX_PID" >/dev/null 2>&1; then
  echo "[fail] fixture server exited"
  cat "$LOG_FILE"
  exit 1
fi

BASE_URL="http://127.0.0.1:${PORT}" SHIPINFO_API_KEY="$TOKEN" bash shipinfo-agent-kit/scripts/e2e_smoke.sh

echo "e2e_auth_fixture: pass"
