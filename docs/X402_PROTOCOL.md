# x402 Integration

Implemented endpoints:

- `GET /topos/api/v1/billing/x402/requirements`
- `POST /topos/api/v1/billing/x402/verify`

Behavior:

- `requirements` returns machine-readable x402 metadata (`protocol`, `x402_version`, `mode`, `accepts`, `headers`, `links`).
- `verify` accepts either:
  - body field `payment` (object), or
  - request header `PAYMENT-SIGNATURE`.
- If payment proof is missing/invalid, API returns `402` and sets `PAYMENT-REQUIRED` challenge header.
- Verify response body fields (envelope `data`):
  - `accepted` (`true|false`)
  - `mode` (`disabled|optional|required`)
  - `reason` (machine-readable reason code)

Configuration:

- `AGENT_X402_MODE=disabled|optional|required` (default `optional`).

Smoke test:

```bash
BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh
```

Manual verify examples:

```bash
# Missing proof -> expected HTTP 402 + PAYMENT-REQUIRED header
curl -i -X POST "https://shipinfo.net/topos/api/v1/billing/x402/verify" \
  -H 'Content-Type: application/json' \
  --data '{"resource":"/topos/api/v1/vessels/lookup"}'

# With proof signature -> expected HTTP 200
curl -i -X POST "https://shipinfo.net/topos/api/v1/billing/x402/verify" \
  -H 'Content-Type: application/json' \
  -H 'PAYMENT-SIGNATURE: stub-signature' \
  --data '{"resource":"/topos/api/v1/vessels/lookup"}'
```

Troubleshooting:

- If `PAYMENT-REQUIRED` header is present but client parsing fails, treat it as malformed challenge payload and retry discovery via:
  - `GET /topos/api/v1/billing/x402/requirements?resource=...`
- Expected `PAYMENT-REQUIRED` payload shape is JSON with at least:
  - `protocol` = `x402`
  - `verify_url` (preferred) or `links.verify` = non-empty URL/path
- For payload drift troubleshooting, run smoke in debug mode to print parsed challenge header payload:
  - `X402_SMOKE_DEBUG=1 BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh`
