#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
BASELINE_DIR="${BASELINE_DIR:-shipinfo-agent-kit/contracts/baseline}"
WORK_DIR="$(mktemp -d)"
cleanup(){ rm -rf "$WORK_DIR"; }
trap cleanup EXIT

OUT_DIR="$WORK_DIR" BASE_URL="$BASE_URL" bash shipinfo-agent-kit/scripts/capture_openapi_snapshot.sh >/tmp/openapi_snapshot.log 2>&1 || {
  cat /tmp/openapi_snapshot.log
  exit 1
}

if [[ ! -f "$BASELINE_DIR/openapi.paths.json" ]]; then
  echo "[fail] missing baseline: $BASELINE_DIR/openapi.paths.json"
  exit 1
fi

if ! diff -u "$BASELINE_DIR/openapi.paths.json" "$WORK_DIR/openapi.paths.json" >/tmp/openapi_diff.txt; then
  echo "[fail] regression detected in openapi.paths.json"
  cat /tmp/openapi_diff.txt
  exit 1
fi

echo "[ok] openapi.paths.json"
echo "openapi_regression: pass"
