#!/usr/bin/env bash
set -euo pipefail

MCP_PORT="${MCP_PORT:-18089}"
SHIPINFO_API_BASE="${SHIPINFO_API_BASE:-https://shipinfo.net/topos/api}"
SHIPINFO_API_KEY="${SHIPINFO_API_KEY:-}"

LOG_FILE="$(mktemp)"
cleanup(){
  if [[ -n "${MCP_PID:-}" ]] && kill -0 "$MCP_PID" >/dev/null 2>&1; then
    kill "$MCP_PID" >/dev/null 2>&1 || true
    wait "$MCP_PID" >/dev/null 2>&1 || true
  fi
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

MCP_PORT="$MCP_PORT" SHIPINFO_API_BASE="$SHIPINFO_API_BASE" SHIPINFO_API_KEY="$SHIPINFO_API_KEY" \
  node shipinfo-agent-kit/packages/mcp-server/src/server.js >"$LOG_FILE" 2>&1 &
MCP_PID=$!

for _ in $(seq 1 25); do
  if curl -sS "http://127.0.0.1:${MCP_PORT}/tools" >/tmp/mcp_matrix_tools.json 2>/dev/null; then
    break
  fi
  sleep 0.2
done

expect_json() {
  local file="$1"
  php -r '$j=json_decode(file_get_contents($argv[1]), true); if(!is_array($j)){fwrite(STDERR,"invalid json\n"); exit(1);} ' "$file"
}

expect_field_eq() {
  local file="$1"
  local field="$2"
  local expected="$3"
  php -r '$j=json_decode(file_get_contents($argv[1]), true); $f=$argv[2]; $e=$argv[3]; if(!is_array($j) || !isset($j[$f]) || (string)$j[$f] !== $e){fwrite(STDERR,"field mismatch\n"); exit(1);} ' "$file" "$field" "$expected"
}

# 1) Missing tool
code=$(curl -sS -o /tmp/mcp_case1.json -w '%{http_code}' -X POST "http://127.0.0.1:${MCP_PORT}/invoke" -H 'Content-Type: application/json' -d '{}')
[[ "$code" == "422" ]] || { echo "[fail] case1 http=$code"; cat /tmp/mcp_case1.json; exit 1; }
expect_json /tmp/mcp_case1.json
expect_field_eq /tmp/mcp_case1.json code missing_tool
echo "[ok] case1 missing_tool"

# 2) Invalid JSON
code=$(printf '{invalid' | curl -sS -o /tmp/mcp_case2.json -w '%{http_code}' -X POST "http://127.0.0.1:${MCP_PORT}/invoke" -H 'Content-Type: application/json' --data-binary @-)
[[ "$code" == "400" ]] || { echo "[fail] case2 http=$code"; cat /tmp/mcp_case2.json; exit 1; }
expect_json /tmp/mcp_case2.json
expect_field_eq /tmp/mcp_case2.json code invalid_json
echo "[ok] case2 invalid_json"

# 3) Unknown tool
code=$(curl -sS -o /tmp/mcp_case3.json -w '%{http_code}' -X POST "http://127.0.0.1:${MCP_PORT}/invoke" -H 'Content-Type: application/json' -d '{"tool":"nope","args":{}}')
[[ "$code" == "404" ]] || { echo "[fail] case3 http=$code"; cat /tmp/mcp_case3.json; exit 1; }
expect_json /tmp/mcp_case3.json
expect_field_eq /tmp/mcp_case3.json code unknown_tool
echo "[ok] case3 unknown_tool"

# 4) Invalid args
code=$(curl -sS -o /tmp/mcp_case4.json -w '%{http_code}' -X POST "http://127.0.0.1:${MCP_PORT}/invoke" -H 'Content-Type: application/json' -d '{"tool":"vessel_lookup","args":{"id":""}}')
[[ "$code" == "422" ]] || { echo "[fail] case4 http=$code"; cat /tmp/mcp_case4.json; exit 1; }
expect_json /tmp/mcp_case4.json
expect_field_eq /tmp/mcp_case4.json code invalid_args
echo "[ok] case4 invalid_args"

# 5) Valid invoke contract (status ok or error)
code=$(curl -sS -o /tmp/mcp_case5.json -w '%{http_code}' -X POST "http://127.0.0.1:${MCP_PORT}/invoke" -H 'Content-Type: application/json' -d '{"tool":"vessel_lookup","args":{"id":"MMSI:563033300"}}')
[[ "$code" == "200" || "$code" == "401" || "$code" == "404" ]] || { echo "[fail] case5 http=$code"; cat /tmp/mcp_case5.json; exit 1; }
expect_json /tmp/mcp_case5.json
php -r '$j=json_decode(file_get_contents($argv[1]), true); if(!is_array($j) || !isset($j["status"]) || !in_array($j["status"], ["ok","error"], true)){fwrite(STDERR,"invalid status\n"); exit(1);} ' /tmp/mcp_case5.json
echo "[ok] case5 valid invoke contract"

echo "mcp_contract_matrix: pass"
