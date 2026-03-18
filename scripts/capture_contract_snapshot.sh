#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
OUT_DIR="${OUT_DIR:-shipinfo-agent-kit/contracts/baseline}"
mkdir -p "$OUT_DIR"

python3 - << 'PY'
import json, os, urllib.request
base=os.environ.get('BASE_URL','https://shipinfo.net/topos/api').rstrip('/')
out=os.environ.get('OUT_DIR','shipinfo-agent-kit/contracts/baseline')

caps=json.load(urllib.request.urlopen(base+'/v1/capabilities'))
schemas=json.load(urllib.request.urlopen(base+'/.well-known/schemas/index.json'))

caps_data=caps.get('data',{})
schemas_data=schemas.get('data',{})

with open(os.path.join(out,'capabilities.data.json'),'w',encoding='utf-8') as f:
    json.dump(caps_data,f,ensure_ascii=False,sort_keys=True,indent=2)
with open(os.path.join(out,'schemas_index.data.json'),'w',encoding='utf-8') as f:
    json.dump(schemas_data,f,ensure_ascii=False,sort_keys=True,indent=2)

print('snapshot: written')
PY
