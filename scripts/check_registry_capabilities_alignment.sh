#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://shipinfo.net/topos/api}"
REGISTRY_FILE="${1:-shipinfo-agent-kit/registry/shipinfo-analytics.json}"
STRICT="${STRICT:-0}"

python3 - << 'PY'
import json, os, sys, urllib.request
base=os.environ.get('BASE_URL','https://shipinfo.net/topos/api').rstrip('/')
reg_file=os.environ.get('REGISTRY_FILE','shipinfo-agent-kit/registry/shipinfo-analytics.json')
strict=os.environ.get('STRICT','0')=='1'

with open(reg_file,'r',encoding='utf-8') as f:
    reg=json.load(f)
cap=json.load(urllib.request.urlopen(base+'/v1/capabilities'))
idx=json.load(urllib.request.urlopen(base+'/.well-known/schemas/index.json'))

schema_keys=set(s.get('schema_key','') for s in idx.get('data',{}).get('schemas',[]))
cap_map={}
for c in cap.get('data',{}).get('capabilities',[]):
    path=c.get('path','')
    if path.startswith('/topos/api'):
        path=path[len('/topos/api'):]
    key=(c.get('method','GET').upper(), path)
    cap_map[key]=c

issues=[]
for t in reg.get('tools',[]):
    method=t.get('method','GET').upper()
    path=t.get('path','')
    cap_key=(method,path)
    if cap_key not in cap_map:
        issues.append(f"missing capability for registry tool {t.get('key')} {method} {path}")
        continue

    c=cap_map[cap_key]
    in_url=t.get('input_schema_url','')
    out_url=t.get('output_schema_url','')
    in_key=in_url.rsplit('/',1)[-1] if in_url else ''
    out_key=out_url.rsplit('/',1)[-1] if out_url else ''

    if in_key and in_key not in schema_keys:
        issues.append(f"registry input schema not in index: {t.get('key')} -> {in_key}")
    if out_key and out_key not in schema_keys:
        issues.append(f"registry output schema not in index: {t.get('key')} -> {out_key}")

    c_in=c.get('input_schema','')
    c_out=c.get('output_schema','')
    if c_in not in ('', 'none') and in_key and c_in != in_key:
        issues.append(f"input schema drift for {t.get('key')}: registry={in_key} capabilities={c_in}")
    if c_out not in ('', 'none') and out_key and c_out != out_key:
        issues.append(f"output schema drift for {t.get('key')}: registry={out_key} capabilities={c_out}")

if issues:
    print('alignment: WARN')
    for i in issues:
        print('- '+i)
    if strict:
        sys.exit(1)
else:
    print('alignment: OK')
PY
