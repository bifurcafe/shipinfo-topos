#!/usr/bin/env bash
set -euo pipefail

REPORT_FILE="${REPORT_FILE:-shipinfo-agent-kit/reports/release_report_latest.json}"
CHECKSUM_FILE="${CHECKSUM_FILE:-shipinfo-agent-kit/reports/checksums_sha256.txt}"
REGISTRY_FILE="${REGISTRY_FILE:-shipinfo-agent-kit/registry/shipinfo-analytics.json}"
OUT_FILE="${OUT_FILE:-shipinfo-agent-kit/reports/release_manifest.json}"

[[ -f "$REPORT_FILE" ]] || { echo "missing report file: $REPORT_FILE"; exit 1; }
[[ -f "$CHECKSUM_FILE" ]] || { echo "missing checksum file: $CHECKSUM_FILE"; exit 1; }
[[ -f "$REGISTRY_FILE" ]] || { echo "missing registry file: $REGISTRY_FILE"; exit 1; }

report_sha=$(sha256sum "$REPORT_FILE" | awk '{print $1}')
checksum_sha=$(sha256sum "$CHECKSUM_FILE" | awk '{print $1}')
registry_sha=$(sha256sum "$REGISTRY_FILE" | awk '{print $1}')

registry_version=$(php -r '$j=json_decode(file_get_contents($argv[1]), true); if(!is_array($j)){exit(1);} echo (string)($j["version"] ?? "");' "$REGISTRY_FILE")

cat > "$OUT_FILE" <<JSON
{
  "generated_at_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "registry_version": "${registry_version}",
  "artifacts": {
    "release_report": {
      "path": "${REPORT_FILE}",
      "sha256": "${report_sha}"
    },
    "checksums_manifest": {
      "path": "${CHECKSUM_FILE}",
      "sha256": "${checksum_sha}"
    },
    "registry_entry": {
      "path": "${REGISTRY_FILE}",
      "sha256": "${registry_sha}"
    }
  },
  "signature_mode": "checksum_manifest"
}
JSON

echo "release_manifest generated: $OUT_FILE"
