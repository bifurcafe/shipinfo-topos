# shipinfo-sdk

Python SDK for ShipInfo agent-native API.

## Install

```bash
pip install shipinfo-sdk
```

## Quickstart

```python
from shipinfo_sdk import ShipInfoClient

client = ShipInfoClient(
    base_url="https://shipinfo.net/topos/api",
    api_key=None,
    agent_headers={
        "name": "demo-agent",
        "vendor": "example-inc",
        "contact": "https://example.com/agent",
        "session": "sess-001",
    },
)

caps = client.capabilities()
print(caps.get("status"))
```

## API

- `capabilities()`
- `policy()`
- `quality()`
- `billing_pricing()`
- `billing_x402_requirements(resource="/topos/api/v1/vessels/lookup")`
- `billing_x402_verify(resource, payment, payment_signature=None)`
- `vessel_lookup(vessel_id)`
- `port_congestion(port_id, range=None, vessel_type=None)`
- `sts_events(**kwargs)`
- `route_stress_index(zone_key=None, range=None)`
- `get_paginated(path, params=None, limit_pages=10, cursor_field="next_cursor", items_field=None)`

## x402 Notes

- On HTTP `402`, `ShipInfoHttpError` includes:
  - `status_code`
  - `retryable`
  - `response_headers`
  - `payment_required` (parsed from `PAYMENT-REQUIRED`/`payment-required` header if available)
- For proof-based verify flow use `payment_signature`; SDK sends `PAYMENT-SIGNATURE` header.

## Fair Value Rule

Paid calls follow payer autonomy semantics:
`agent_self_assessed_fair_value`, `paid_interactions_only`.
