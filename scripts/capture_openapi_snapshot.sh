#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
OUT_DIR="${OUT_DIR:-shipinfo-agent-kit/contracts/baseline}"
mkdir -p "$OUT_DIR"

python3 - << 'PY'
import json, os, urllib.request
base=os.environ.get('BASE_URL','https://shipinfo.net/topos/api').rstrip('/')
out=os.environ.get('OUT_DIR','shipinfo-agent-kit/contracts/baseline')

doc=json.load(urllib.request.urlopen(base+'/.well-known/openapi.json'))
data=doc.get('data',{})
paths=data.get('paths',{}) if isinstance(data,dict) else {}

with open(os.path.join(out,'openapi.paths.json'),'w',encoding='utf-8') as f:
    json.dump(paths,f,ensure_ascii=False,sort_keys=True,indent=2)

print('openapi snapshot: written')
PY
