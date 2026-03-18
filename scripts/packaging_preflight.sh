#!/usr/bin/env bash
set -euo pipefail

check_file() {
  local f="$1"
  [[ -f "$f" ]] || { echo "[fail] missing file: $f"; exit 1; }
  echo "[ok] $f"
}

echo "[preflight] js package"
check_file shipinfo-agent-kit/packages/sdk-js/package.json
check_file shipinfo-agent-kit/packages/sdk-js/src/index.js
check_file shipinfo-agent-kit/packages/sdk-js/src/index.d.ts
check_file shipinfo-agent-kit/packages/sdk-js/README.md

php -r '$j=json_decode(file_get_contents("shipinfo-agent-kit/packages/sdk-js/package.json"), true); if(!is_array($j)){fwrite(STDERR,"invalid js package.json\n"); exit(1);} foreach(["name","version","main","types"] as $k){ if(!isset($j[$k])||!is_string($j[$k])||$j[$k]===""){ fwrite(STDERR,"missing js field: $k\n"); exit(2);} } echo "[ok] js package.json fields\n";'

echo "[preflight] py package"
check_file shipinfo-agent-kit/packages/sdk-py/pyproject.toml
check_file shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/__init__.py
check_file shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/client.py
check_file shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/errors.py
check_file shipinfo-agent-kit/packages/sdk-py/README.md

grep -q '^\[project\]' shipinfo-agent-kit/packages/sdk-py/pyproject.toml
grep -q '^name = ' shipinfo-agent-kit/packages/sdk-py/pyproject.toml
grep -q '^version = ' shipinfo-agent-kit/packages/sdk-py/pyproject.toml
grep -q '^requires-python = ' shipinfo-agent-kit/packages/sdk-py/pyproject.toml
echo "[ok] pyproject fields"

echo "packaging_preflight: pass"
