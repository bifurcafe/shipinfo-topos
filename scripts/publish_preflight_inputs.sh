#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT_DIR="$ROOT_DIR/shipinfo-agent-kit"
INPUT_FILE="${1:-$KIT_DIR/release_package/PUBLISH_INPUTS.env}"

load_env_file_safe() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  while IFS= read -r raw || [[ -n "$raw" ]]; do
    local line="$raw"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    [[ "${line:0:1}" == "#" ]] && continue
    [[ "$line" != *"="* ]] && continue
    local key="${line%%=*}"
    local val="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    if [[ "$val" == \"*\" && "$val" == *\" ]]; then
      val="${val:1:${#val}-2}"
    elif [[ "$val" == \'*\' && "$val" == *\' ]]; then
      val="${val:1:${#val}-2}"
    fi
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    export "$key=$val"
  done < "$file"
}

read_json_field() {
  local file="$1"
  local key="$2"
  php -r '$j=json_decode(file_get_contents($argv[1]),true); if(!is_array($j)){exit(1);} echo (string)($j[$argv[2]] ?? "");' "$file" "$key" 2>/dev/null || true
}

read_pyproject_name() {
  local file="$1"
  awk -F'=' '/^[[:space:]]*name[[:space:]]*=[[:space:]]*"/ {gsub(/"/, "", $2); gsub(/[[:space:]]/, "", $2); print $2; exit}' "$file" 2>/dev/null || true
}

print_missing_list() {
  local label="$1"
  shift
  local missing=()
  local key
  for key in "$@"; do
    if [[ -z "${!key:-}" ]]; then
      missing+=("$key")
    fi
  done
  if (( ${#missing[@]} == 0 )); then
    echo "${label}=ok"
  else
    echo "${label}=missing"
    printf '%s\n' "${missing[@]}" | sed 's/^/missing: /'
  fi
}

load_env_file_safe "$INPUT_FILE"

required_config=(
  GITHUB_ORG_OR_USER
  GITHUB_REPO
  GITHUB_REPO_VISIBILITY
  NPM_PACKAGE_NAME
  NPM_ACCESS
  PYPI_PACKAGE_NAME
  PYPI_PUBLISH_MODE
  MCP_REGISTRY_MODE
  MCP_REGISTRY_REPO_URL
  SCHEMA_BASE_URL
  API_BASE_URL
)

required_secrets=(
  GITHUB_TOKEN
  NPM_TOKEN
  PYPI_API_TOKEN
  MCP_REGISTRY_GITHUB_TOKEN
)

echo "publish_preflight_input_file=${INPUT_FILE}"
print_missing_list "config_vars" "${required_config[@]}"
print_missing_list "secret_vars" "${required_secrets[@]}"

sdk_js_name="$(read_json_field "$KIT_DIR/packages/sdk-js/package.json" "name")"
sdk_py_name="$(read_pyproject_name "$KIT_DIR/packages/sdk-py/pyproject.toml")"

if [[ -n "${NPM_PACKAGE_NAME:-}" && -n "$sdk_js_name" && "$NPM_PACKAGE_NAME" != "$sdk_js_name" ]]; then
  echo "warning: NPM_PACKAGE_NAME_mismatch env=${NPM_PACKAGE_NAME} package_json=${sdk_js_name}"
fi
if [[ -n "${PYPI_PACKAGE_NAME:-}" && -n "$sdk_py_name" && "$PYPI_PACKAGE_NAME" != "$sdk_py_name" ]]; then
  echo "warning: PYPI_PACKAGE_NAME_mismatch env=${PYPI_PACKAGE_NAME} pyproject=${sdk_py_name}"
fi

has_missing=0
for key in "${required_config[@]}" "${required_secrets[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    has_missing=1
  fi
done

echo "next_step_1=BASE_URL=${API_BASE_URL:-https://shipinfo.net/topos/api} SHIPINFO_API_BASE=${API_BASE_URL:-https://shipinfo.net/topos/api} bash shipinfo-agent-kit/scripts/release_gate.sh"
echo "next_step_2=bash shipinfo-agent-kit/scripts/build_release_package.sh"
echo "next_step_3=GITHUB_TOKEN=<token> gh repo create ${GITHUB_ORG_OR_USER:-<org>}/${GITHUB_REPO:-shipinfo-agent-kit} --public --source shipinfo-agent-kit --push"
echo "next_step_4=cd shipinfo-agent-kit/packages/sdk-js && NODE_AUTH_TOKEN=<token> npm publish --access ${NPM_ACCESS:-public}"
echo "next_step_5=cd shipinfo-agent-kit/packages/sdk-py && TWINE_USERNAME=__token__ TWINE_PASSWORD=<token> python3 -m twine upload dist/*"
echo "next_step_6=GITHUB_TOKEN=<token> gh pr create --repo ${MCP_REGISTRY_REPO_URL:-<registry/repo>} --title \"Add shipinfo-analytics MCP entry\" --body \"ShipInfo MCP registry entry update\""

if (( has_missing == 1 )); then
  echo "publish_preflight_status=blocked"
  exit 1
fi

echo "publish_preflight_status=ready"
