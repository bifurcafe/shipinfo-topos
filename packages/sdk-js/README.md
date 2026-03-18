# @shipinfo/sdk

JavaScript SDK for ShipInfo agent-native API.

## Install

```bash
npm install @shipinfo/sdk
```

## Quickstart

```js
import { ShipInfoClient } from "@shipinfo/sdk";

const client = new ShipInfoClient({
  baseUrl: "https://shipinfo.net/topos/api",
  apiKey: process.env.SHIPINFO_API_KEY || null,
  agentHeaders: {
    name: "demo-agent",
    vendor: "example-inc",
    contact: "https://example.com/agent",
    session: `sess-${Date.now()}`,
  },
});

const caps = await client.capabilities();
console.log(caps.status);
```

## API

- `capabilities()`
- `policy()`
- `quality()`
- `billingPricing()`
- `billingX402Requirements({ resource })`
- `billingX402Verify({ resource, payment, paymentSignature? })`
- `vesselLookup({ id })`
- `portCongestion({ port_id, range?, vessel_type? })`
- `stsEvents({ from?, to?, zone?, cursor?, limit? })`
- `routeStressIndex({ zone_key?, range? })`
- `getPaginated(path, query, { limitPages, cursorField, itemsPath })`

## x402 Notes

- If API returns HTTP `402`, thrown error contains:
  - `status`
  - `body`
  - `retryable`
  - `requestId`
  - `paymentRequired` (parsed from `PAYMENT-REQUIRED`/`payment-required` header when present)
  - `paymentSignature`
- For verify flows, pass proof via `paymentSignature` (sent as `PAYMENT-SIGNATURE` header).

## Fair Value Rule

Paid calls are controlled by payer autonomy semantics:
`agent_self_assessed_fair_value`, `paid_interactions_only`.
