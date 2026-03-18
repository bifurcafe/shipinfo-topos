#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="${REPORT_FILE:-shipinfo-agent-kit/reports/release_report_latest.json}"

[[ -f "$REPORT_FILE" ]] || { echo "missing report file: $REPORT_FILE"; exit 1; }

php -r '
$f = $argv[1];
$j = json_decode(file_get_contents($f), true);
if (!is_array($j)) {
  fwrite(STDERR, "invalid json\n");
  exit(2);
}
$required = array("generated_at_utc", "base_url", "shipinfo_api_base", "status", "checks");
foreach ($required as $k) {
  if (!array_key_exists($k, $j)) {
    fwrite(STDERR, "missing key: $k\n");
    exit(3);
  }
}
if (!in_array($j["status"], array("ok", "fail"), true)) {
  fwrite(STDERR, "invalid status\n");
  exit(4);
}
if (!is_array($j["checks"]) || count($j["checks"]) === 0) {
  fwrite(STDERR, "checks must be non-empty array\n");
  exit(5);
}
foreach ($j["checks"] as $idx => $c) {
  if (!is_array($c)) {
    fwrite(STDERR, "check[$idx] not object\n");
    exit(6);
  }
  foreach (array("name", "status", "message") as $k) {
    if (!array_key_exists($k, $c)) {
      fwrite(STDERR, "check[$idx] missing key: $k\n");
      exit(7);
    }
  }
  if (!in_array($c["status"], array("ok", "fail"), true)) {
    fwrite(STDERR, "check[$idx] invalid status\n");
    exit(8);
  }
}
$requiredChecks = array("syntax_js", "syntax_mcp", "syntax_py", "registry_links", "registry_capability_alignment", "e2e_unauth", "x402_smoke", "mcp_smoke", "mcp_contract_matrix", "agent_platform_smoke", "e2e_auth_fixture", "release_artifact_paths", "release_artifact_paths_json", "release_artifact_chain");
$present = array();
foreach ($j["checks"] as $c) {
  $present[(string)$c["name"]] = true;
}
foreach ($requiredChecks as $name) {
  if (!isset($present[$name])) {
    fwrite(STDERR, "missing required check: $name\n");
    exit(9);
  }
}
' "$REPORT_FILE"

echo "validate_release_report: pass"
