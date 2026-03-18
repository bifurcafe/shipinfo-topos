#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
SHIPINFO_API_BASE="${SHIPINFO_API_BASE:-$BASE_URL}"
SHIPINFO_API_KEY="${SHIPINFO_API_KEY:-}"
AGENT_ADMIN_TOKEN="${AGENT_ADMIN_TOKEN:-}"
OUT_FILE="${OUT_FILE:-shipinfo-agent-kit/reports/release_report_latest.json}"

run_check() {
  local name="$1"
  shift
  if "$@" >/tmp/release_report_check.log 2>&1; then
    echo "$name|ok|"
  else
    local msg
    msg=$(tr '\n' ' ' < /tmp/release_report_check.log | sed 's/"/\\"/g')
    echo "$name|fail|$msg"
  fi
}

results=()
results+=("$(run_check syntax_js node --check shipinfo-agent-kit/packages/sdk-js/src/index.js)")
results+=("$(run_check syntax_mcp node --check shipinfo-agent-kit/packages/mcp-server/src/server.js)")
results+=("$(run_check syntax_py python3 -m py_compile shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/client.py shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/errors.py)")
results+=("$(run_check registry_links bash shipinfo-agent-kit/scripts/check_registry_links.sh)")
results+=("$(run_check registry_capability_alignment env BASE_URL="$BASE_URL" REGISTRY_FILE="shipinfo-agent-kit/registry/shipinfo-analytics.json" STRICT=1 bash shipinfo-agent-kit/scripts/check_registry_capabilities_alignment.sh)")
results+=("$(run_check e2e_unauth env BASE_URL="$BASE_URL" bash shipinfo-agent-kit/scripts/e2e_smoke.sh)")
results+=("$(run_check x402_smoke env BASE_URL="$BASE_URL" bash shipinfo-agent-kit/scripts/x402_smoke.sh)")
results+=("$(run_check mcp_smoke env SHIPINFO_API_BASE="$SHIPINFO_API_BASE" SHIPINFO_API_KEY="$SHIPINFO_API_KEY" bash shipinfo-agent-kit/scripts/mcp_smoke.sh)")
results+=("$(run_check mcp_contract_matrix env SHIPINFO_API_BASE="$SHIPINFO_API_BASE" SHIPINFO_API_KEY="$SHIPINFO_API_KEY" bash shipinfo-agent-kit/scripts/mcp_contract_matrix.sh)")
results+=("$(run_check agent_platform_smoke env BASE_URL="$BASE_URL" AGENT_ADMIN_TOKEN="$AGENT_ADMIN_TOKEN" bash scripts/agents/smoke_agent_platform.sh)")
results+=("$(run_check e2e_auth_fixture bash shipinfo-agent-kit/scripts/e2e_auth_fixture.sh)")
results+=("$(run_check release_artifact_paths bash scripts/agents/validate_release_artifact_paths.sh)")
results+=("$(run_check release_artifact_paths_json bash scripts/agents/validate_release_artifact_paths_json.sh)")
results+=("$(run_check release_artifact_chain bash -lc 'bash scripts/agents/release_artifact_paths.sh >/dev/null && bash scripts/agents/release_artifact_paths_json.sh >/dev/null && bash scripts/agents/validate_release_artifact_paths.sh >/dev/null && bash scripts/agents/validate_release_artifact_paths_json.sh >/dev/null')")

status="ok"
for row in "${results[@]}"; do
  IFS='|' read -r _name st _msg <<< "$row"
  if [[ "$st" != "ok" ]]; then
    status="fail"
    break
  fi
done

{
  echo "{"
  echo "  \"generated_at_utc\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"base_url\": \"$BASE_URL\","
  echo "  \"shipinfo_api_base\": \"$SHIPINFO_API_BASE\","
  echo "  \"status\": \"$status\","
  echo "  \"checks\": ["
  n=${#results[@]}
  i=0
  for row in "${results[@]}"; do
    i=$((i+1))
    IFS='|' read -r name st msg <<< "$row"
    echo "    {\"name\":\"$name\",\"status\":\"$st\",\"message\":\"$msg\"}"$( [[ "$i" -lt "$n" ]] && echo ',' )
  done
  echo "  ]"
  echo "}"
} > "$OUT_FILE"

cat "$OUT_FILE"
