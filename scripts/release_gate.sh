#!/usr/bin/env bash
set -euo pipefail

echo "[gate] syntax checks"
node --check shipinfo-agent-kit/packages/sdk-js/src/index.js
node --check shipinfo-agent-kit/packages/mcp-server/src/server.js
python3 -m py_compile shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/client.py shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/errors.py
bash -n shipinfo-agent-kit/scripts/e2e_smoke.sh
bash -n shipinfo-agent-kit/scripts/x402_smoke.sh
bash -n shipinfo-agent-kit/scripts/e2e_auth_fixture.sh
bash -n shipinfo-agent-kit/scripts/check_registry_links.sh
bash -n shipinfo-agent-kit/scripts/check_registry_capabilities_alignment.sh
bash -n shipinfo-agent-kit/scripts/mcp_smoke.sh
bash -n shipinfo-agent-kit/scripts/mcp_contract_matrix.sh
bash -n shipinfo-agent-kit/scripts/release_report.sh
bash -n shipinfo-agent-kit/scripts/validate_release_report.sh
bash -n shipinfo-agent-kit/scripts/packaging_preflight.sh
bash -n shipinfo-agent-kit/scripts/capture_contract_snapshot.sh
bash -n shipinfo-agent-kit/scripts/check_contract_regression.sh
bash -n shipinfo-agent-kit/scripts/capture_openapi_snapshot.sh
bash -n shipinfo-agent-kit/scripts/check_openapi_regression.sh
bash -n shipinfo-agent-kit/scripts/generate_checksums.sh
bash -n shipinfo-agent-kit/scripts/verify_checksums.sh
bash -n shipinfo-agent-kit/scripts/generate_release_manifest.sh
bash -n scripts/agents/smoke_agent_platform.sh
bash -n scripts/agents/ops_agent_platform_handoff.sh
bash -n scripts/agents/ops_health_snapshot.sh
bash -n scripts/agents/validate_ops_health_snapshot.sh
bash -n scripts/agents/ops_health_status.sh
bash -n scripts/agents/release_artifact_paths.sh
bash -n scripts/agents/release_artifact_paths_json.sh
bash -n scripts/agents/validate_release_artifact_paths.sh
bash -n scripts/agents/validate_release_artifact_paths_json.sh
bash -n scripts/agents/release_report_fail_checks.sh

echo "[gate] packaging preflight"
bash shipinfo-agent-kit/scripts/packaging_preflight.sh

echo "[gate] checksums"
bash shipinfo-agent-kit/scripts/generate_checksums.sh
bash shipinfo-agent-kit/scripts/verify_checksums.sh

echo "[gate] contract regression"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" bash shipinfo-agent-kit/scripts/check_contract_regression.sh

echo "[gate] openapi regression"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" bash shipinfo-agent-kit/scripts/check_openapi_regression.sh

echo "[gate] registry links"
bash shipinfo-agent-kit/scripts/check_registry_links.sh

echo "[gate] registry/capabilities alignment"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" \
REGISTRY_FILE="shipinfo-agent-kit/registry/shipinfo-analytics.json" \
STRICT=1 bash shipinfo-agent-kit/scripts/check_registry_capabilities_alignment.sh

echo "[gate] e2e smoke unauth"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" bash shipinfo-agent-kit/scripts/e2e_smoke.sh

echo "[gate] x402 smoke"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" bash shipinfo-agent-kit/scripts/x402_smoke.sh

echo "[gate] mcp smoke"
SHIPINFO_API_BASE="${SHIPINFO_API_BASE:-https://shipinfo.net/topos/api}" \
  SHIPINFO_API_KEY="${SHIPINFO_API_KEY:-}" \
  bash shipinfo-agent-kit/scripts/mcp_smoke.sh

echo "[gate] mcp contract matrix"
SHIPINFO_API_BASE="${SHIPINFO_API_BASE:-https://shipinfo.net/topos/api}" \
  SHIPINFO_API_KEY="${SHIPINFO_API_KEY:-}" \
  bash shipinfo-agent-kit/scripts/mcp_contract_matrix.sh

echo "[gate] agent platform smoke"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" \
  AGENT_ADMIN_TOKEN="${AGENT_ADMIN_TOKEN:-}" \
  bash scripts/agents/smoke_agent_platform.sh

echo "[gate] auth fixture smoke"
bash shipinfo-agent-kit/scripts/e2e_auth_fixture.sh

if [[ -n "${SHIPINFO_API_KEY:-}" ]]; then
  echo "[gate] e2e smoke auth"
  BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" SHIPINFO_API_KEY="$SHIPINFO_API_KEY" bash shipinfo-agent-kit/scripts/e2e_smoke.sh
else
  echo "[gate] auth smoke skipped (SHIPINFO_API_KEY not set)"
fi

echo "[gate] release report"
BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}" SHIPINFO_API_BASE="${SHIPINFO_API_BASE:-https://shipinfo.net/topos/api}" SHIPINFO_API_KEY="${SHIPINFO_API_KEY:-}" bash shipinfo-agent-kit/scripts/release_report.sh

echo "[gate] release report schema check"
REPORT_FILE="shipinfo-agent-kit/reports/release_report_latest.json" bash shipinfo-agent-kit/scripts/validate_release_report.sh

echo "[gate] release manifest"
bash shipinfo-agent-kit/scripts/generate_release_manifest.sh

echo "[gate] release artifact paths"
bash scripts/agents/release_artifact_paths.sh
bash scripts/agents/release_artifact_paths_json.sh
bash scripts/agents/validate_release_artifact_paths.sh
bash scripts/agents/validate_release_artifact_paths_json.sh

echo "[gate] x402 contract scope: mode-parity, challenge-payload-json, verify-missing-proof(mode/reason), verify-success(mode/reason)"
echo "release_gate: pass"
