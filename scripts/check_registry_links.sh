#!/usr/bin/env bash
set -euo pipefail

REGISTRY_FILE="${1:-shipinfo-agent-kit/registry/shipinfo-analytics.json}"

php -r '
$f=$argv[1];
$j=json_decode(file_get_contents($f), true);
if(!is_array($j)){fwrite(STDERR, "invalid registry json\n"); exit(1);} 
$urls=array();
if(isset($j["server"]["base_url"]) && is_string($j["server"]["base_url"])) {
  $base=rtrim($j["server"]["base_url"], "/");
  $urls[]=$base . "/v1/ping";
}
$groups=array("quality_signals","discoverability");
foreach($groups as $g){
  if(!isset($j[$g]) || !is_array($j[$g])) { continue; }
  foreach($j[$g] as $v){ if(is_string($v) && $v!=="") { $urls[]=$v; } }
}
if(isset($j["tools"]) && is_array($j["tools"])) {
  foreach($j["tools"] as $t){
    if(!is_array($t)) { continue; }
    $keys=array("input_schema_url","output_schema_url");
    foreach($keys as $k){
      if(isset($t[$k]) && is_string($t[$k]) && $t[$k]!=="") { $urls[]=$t[$k]; }
    }
  }
}
foreach($urls as $u){ echo $u, "\n"; }
' "$REGISTRY_FILE" | while IFS= read -r u; do
  code=$(curl -sS -L -o /tmp/regcheck_body.txt -w '%{http_code}' "$u")
  if [[ "$code" == "405" ]]; then
    echo "[ok] $u (method_not_allowed_for_get)"
    continue
  fi
  if [[ "$code" -lt 200 || "$code" -ge 400 ]]; then
    echo "[fail] $u http=$code"
    exit 1
  fi
  echo "[ok] $u"
done

echo "registry_links: pass"
