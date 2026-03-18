#!/usr/bin/env bash
set -euo pipefail

OUT_FILE="${OUT_FILE:-shipinfo-agent-kit/reports/checksums_sha256.txt}"

files=(
  shipinfo-agent-kit/registry/shipinfo-analytics.json
  shipinfo-agent-kit/schemas/envelope.json
  shipinfo-agent-kit/schemas/vessel_lookup_input.json
  shipinfo-agent-kit/schemas/vessel_lookup_output.json
  shipinfo-agent-kit/schemas/port_congestion_input.json
  shipinfo-agent-kit/schemas/port_congestion_output.json
  shipinfo-agent-kit/schemas/sts_events_input.json
  shipinfo-agent-kit/schemas/sts_events_output.json
  shipinfo-agent-kit/schemas/route_stress_input.json
  shipinfo-agent-kit/schemas/route_stress_output.json
  shipinfo-agent-kit/packages/sdk-js/src/index.js
  shipinfo-agent-kit/packages/sdk-js/src/index.d.ts
  shipinfo-agent-kit/packages/sdk-js/package.json
  shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/client.py
  shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/errors.py
  shipinfo-agent-kit/packages/sdk-py/pyproject.toml
  shipinfo-agent-kit/packages/mcp-server/src/server.js
)

for f in "${files[@]}"; do
  [[ -f "$f" ]] || { echo "missing file: $f"; exit 1; }
done

: > "$OUT_FILE"
for f in "${files[@]}"; do
  sha256sum "$f" >> "$OUT_FILE"
done

echo "checksums generated: $OUT_FILE"
