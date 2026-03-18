#!/usr/bin/env bash
set -euo pipefail

MCP_PORT="${MCP_PORT:-18088}"
SHIPINFO_API_BASE="${SHIPINFO_API_BASE:-https://shipinfo.net/topos/api}"
SHIPINFO_API_KEY="${SHIPINFO_API_KEY:-}"

LOG_FILE="$(mktemp)"

cleanup() {
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
  if curl -sS "http://127.0.0.1:${MCP_PORT}/tools" >/tmp/mcp_tools.json 2>/dev/null; then
    break
  fi
  sleep 0.2
done

if ! kill -0 "$MCP_PID" >/dev/null 2>&1; then
  echo "[fail] mcp server exited"
  cat "$LOG_FILE"
  exit 1
fi

php -r '$j=json_decode(file_get_contents("/tmp/mcp_tools.json"), true); if(!is_array($j)||!isset($j["tools"])||!is_array($j["tools"])) {fwrite(STDERR,"invalid /tools payload\n"); exit(2);} if(!in_array("vessel_lookup", $j["tools"], true)) {fwrite(STDERR,"missing tool vessel_lookup\n"); exit(3);} echo "[ok] /tools\n";'

curl -sS -X POST "http://127.0.0.1:${MCP_PORT}/invoke" \
  -H 'Content-Type: application/json' \
  -d '{"tool":"vessel_lookup","args":{"id":"MMSI:563033300"}}' >/tmp/mcp_invoke.json

if [[ -n "$SHIPINFO_API_KEY" ]]; then
  php -r '
  $j=json_decode(file_get_contents("/tmp/mcp_invoke.json"), true);
  if(!is_array($j)){fwrite(STDERR,"invalid /invoke json\n"); exit(2);} 
  if(isset($j["status"]) && $j["status"] === "ok") { echo "[ok] /invoke status=ok (auth mode)\n"; exit(0); }
  fwrite(STDERR,"expected status=ok in auth mode\n");
  var_export($j);
  exit(5);
  '
else
  php -r '
  $j=json_decode(file_get_contents("/tmp/mcp_invoke.json"), true);
  if(!is_array($j)){fwrite(STDERR,"invalid /invoke json\n"); exit(2);} 
  if(isset($j["status"]) && $j["status"] === "ok") { echo "[ok] /invoke status=ok\n"; exit(0); }
  if(isset($j["status"]) && $j["status"] === "error") {
    if(!isset($j["code"])) { fwrite(STDERR, "error payload without code\n"); exit(4); }
    echo "[ok] /invoke status=error code=" . $j["code"] . "\n";
    exit(0);
  }
  fwrite(STDERR,"unexpected /invoke payload\n");
  exit(5);
  '
fi

echo "mcp_smoke: pass"
