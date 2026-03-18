#!/usr/bin/env bash
set -euo pipefail

SUM_FILE="${SUM_FILE:-shipinfo-agent-kit/reports/checksums_sha256.txt}"
[[ -f "$SUM_FILE" ]] || { echo "missing checksum manifest: $SUM_FILE"; exit 1; }

sha256sum -c "$SUM_FILE"
echo "checksums_verify: pass"
