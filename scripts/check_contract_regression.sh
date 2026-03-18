#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
BASELINE_DIR="${BASELINE_DIR:-shipinfo-agent-kit/contracts/baseline}"
WORK_DIR="$(mktemp -d)"
cleanup(){ rm -rf "$WORK_DIR"; }
trap cleanup EXIT

OUT_DIR="$WORK_DIR" BASE_URL="$BASE_URL" bash shipinfo-agent-kit/scripts/capture_contract_snapshot.sh >/tmp/contract_snapshot.log 2>&1 || {
  cat /tmp/contract_snapshot.log
  exit 1
}

for f in capabilities.data.json schemas_index.data.json; do
  if [[ ! -f "$BASELINE_DIR/$f" ]]; then
    echo "[fail] missing baseline: $BASELINE_DIR/$f"
    exit 1
  fi
  if ! diff -u "$BASELINE_DIR/$f" "$WORK_DIR/$f" >/tmp/contract_diff.txt; then
    echo "[fail] regression detected in $f"
    cat /tmp/contract_diff.txt
    exit 1
  fi
  echo "[ok] $f"
done

echo "contract_regression: pass"
