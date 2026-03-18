#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT_DIR="$ROOT_DIR/shipinfo-agent-kit"
DIST_DIR="$KIT_DIR/release_package/dist"

TS="$(date -u +%Y%m%d_%H%M%S_UTC)"
STAGE_DIR="$DIST_DIR/shipinfo_agent_kit_publish_${TS}"
TAR_PATH="$DIST_DIR/shipinfo_agent_kit_publish_${TS}.tar.gz"

mkdir -p "$DIST_DIR"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

copy_path() {
  local rel="$1"
  local src="$KIT_DIR/$rel"
  local dst="$STAGE_DIR/$rel"
  if [[ -d "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
  elif [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  else
    echo "[warn] missing: $rel" >&2
  fi
}

copy_path "registry/shipinfo-analytics.json"
copy_path "schemas"
copy_path "packages/mcp-server"
copy_path "packages/sdk-js"
copy_path "packages/sdk-py"
copy_path "docs/MCP_REGISTRY_PUBLISH.md"
copy_path "docs/NPM_PUBLISH.md"
copy_path "docs/PYPI_PUBLISH.md"
copy_path "docs/RELEASE_CHECKLIST.md"
copy_path "reports/release_report_latest.json"
copy_path "reports/checksums_sha256.txt"
copy_path "reports/release_manifest.json"
copy_path "release_package/README_RU.md"
copy_path "release_package/PUBLISH_INPUTS.template.env"

cat > "$STAGE_DIR/PUBLISH_COMMANDS.txt" <<'TXT'
# 1) Run gate
bash shipinfo-agent-kit/scripts/release_gate.sh

# 2) npm publish (follow docs/NPM_PUBLISH.md)

# 3) PyPI publish (follow docs/PYPI_PUBLISH.md)

# 4) MCP registry PR (follow docs/MCP_REGISTRY_PUBLISH.md)
TXT

tar -C "$DIST_DIR" -czf "$TAR_PATH" "$(basename "$STAGE_DIR")"
echo "release_package_ready=$TAR_PATH"
