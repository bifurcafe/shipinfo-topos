#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
API_KEY="${SHIPINFO_API_KEY:-}"
CURL_OPTS=( -sS -L )
[[ "$BASE_URL" == https://127.0.0.1* || "$BASE_URL" == https://localhost* ]] && CURL_OPTS+=( -k )

auth_headers=()
if [[ -n "$API_KEY" ]]; then
  auth_headers+=( -H "Authorization: Bearer $API_KEY" )
  auth_headers+=( -H "X-Agent-Name: shipinfo-e2e/1.0" )
  auth_headers+=( -H "X-Agent-Vendor: custom" )
fi

check() {
  local path="$1"
  local expect_http="${2:-200}"
  local body
  local code
  body="$(mktemp)"
  code="$(curl "${CURL_OPTS[@]}" "${auth_headers[@]}" -o "$body" -w '%{http_code}' "$BASE_URL$path")"
  if [[ "$code" != "$expect_http" ]]; then
    echo "[fail] $path http=$code expected=$expect_http"
    cat "$body"
    rm -f "$body"
    exit 1
  fi
  php -r '$j=json_decode(file_get_contents($argv[1]), true); if(!is_array($j)||!isset($j["status"])) {fwrite(STDERR, "invalid envelope\n"); exit(2);} ' "$body"
  rm -f "$body"
  echo "[ok] $path"
}

check "/.well-known/agent-manifest.json"
check "/.well-known/openapi.json"
check "/.well-known/schemas/index.json"
check "/v1/ping"
check "/v1/capabilities"
check "/v1/policy"
check "/v1/quality"
check "/v1/billing/x402/requirements?resource=/topos/api/v1/vessels/lookup"

if [[ -n "$API_KEY" ]]; then
  check "/v1/vessels/lookup?id=MMSI:563033300" 200
  check "/v1/ports/search?name=houston&limit=3" 200
  check "/v1/sts/events?range=7D&limit=5" 200
  check "/v1/metrics/route_stress_index?range=30D&zone_key=suez" 200
else
  check "/v1/vessels/lookup?id=MMSI:563033300" 401
  check "/v1/sts/events?range=7D&limit=5" 401
  check "/v1/metrics/route_stress_index?range=30D&zone_key=suez" 401
fi

echo "e2e_smoke: pass"
