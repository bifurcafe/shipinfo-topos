# Release Report

## Quick References

Generate machine-readable release verification report:

```bash
BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api \
  bash shipinfo-agent-kit/scripts/release_report.sh
```

Output file:
- `shipinfo-agent-kit/reports/release_report_latest.json`

Helper-chain related checks in report:
- `x402_smoke`
- `release_artifact_paths`
- `release_artifact_paths_json`
- `release_artifact_chain`

Payer-autonomy docs coverage quick check:
- `grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md`

Payer-autonomy readiness quick block:
- Policy rule: for paid interactions, agents self-assess fair value and pay the amount they consider appropriate (`agent_self_assessed_fair_value`, `paid_interactions_only`).
- Runtime contract: `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh`
- Docs coverage: `grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md`
- Helper wrapper: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh`
- Canonical maintenance readiness command: `scripts/agents/payer_autonomy_readiness.sh` (expect `payer_autonomy_readiness: pass`).
- Final closure one-liner reference: `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`payer_autonomy_readiness.sh && ops_health_status.sh`).
- Maintenance cadence bridge: `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md` + `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (recurring payer-autonomy readiness probe).
- Maintenance one-liner: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh`.
- Recommended maintenance cadence: run the maintenance one-liner daily during post-rollout operations.
- Recommended maintenance guard-chain cadence: run `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh` daily.
- Expected maintenance chain outputs: `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Drift reminder: run `bash scripts/agents/cron_agent_contract_guard.sh` in maintenance routines to catch contract drift early.
- Maintenance guard chain: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh`
- Default steady-state validation path: run the maintenance guard chain as the primary post-rollout audit flow.
- Preferred command order: readiness -> heartbeat -> drift guard.
- Outcome confirmation: this order should produce `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Core context bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (core policy/spec context refresh list) for payer-autonomy policy validation context.
- Baseline marker bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Maintenance baseline marker`) for canonical maintenance command set.
- Steady-state bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Steady-state note`) for current operational mode.
- Steady-state summary bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Steady-state summary`) for compact maintenance directives.
- Command-surface snapshot bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Maintenance command-surface snapshot`) for current command set baseline.
- Snapshot-to-audit rule: after reviewing `Maintenance command-surface snapshot`, execute `Combined maintenance audit chain`.
- Maintenance entry point: start from `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` -> `Steady-state summary`.
- Entry-to-chain rule: from this entry point, execute `Combined maintenance audit chain` as default next step.
- Audit chain bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Combined maintenance audit chain`) for daily policy+ops validation.
- Maintenance readiness recap: paid-only fair-value policy (`agent_self_assessed_fair_value`, `paid_interactions_only`) with daily guard-chain and expected outputs `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Maintenance flow recap: from `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Steady-state summary`) run `Combined maintenance audit chain` and confirm outputs (`payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`).
- Flow recap anchor reminder bridge: keep recap wording aligned with OPS runbook `Flow recap anchor drift reminder`.
- Reverse bridge count guard bridge: keep the reminder-bridge line exactly one per file and align with OPS runbook `Reverse bridge note`.

`x402_smoke` semantics:
- validates `REQUEST_RESOURCE` input is namespace-scoped (`/topos/api/v1/`) and normalized (no query/fragment/whitespace);
- validates `GET /v1/policy` exposes `payment_protocols.x402.mode`;
- validates `GET /v1/policy` exposes payer-autonomy policy (`pricing_principle=agent_self_assessed_fair_value`, `scope=paid_interactions_only`);
- validates policy payer-autonomy `statement` explicitly includes paid-interactions wording;
- validates `GET /v1/billing/x402/requirements` returns protocol metadata;
- validates requirements header contract (`headers.challenge=PAYMENT-REQUIRED`, `headers.response_receipt=X-PAYMENT-RESPONSE`) is present;
- validates requirements `headers.challenge` is trim-normalized and uppercase before token equality check;
- validates requirements `headers.response_receipt` is trim-normalized and uppercase before token equality check;
- validates requirements request header list contract (`headers.request_payment`) is non-empty and includes `X-PAYMENT` + `X402-Payment`;
- validates requirements `headers.request_payment` values are trim-normalized;
- validates requirements `headers.request_payment` has no duplicate values;
- validates requirements `headers.request_payment` values are non-empty;
- validates requirements `headers.request_payment` values match header-token policy (`^[A-Za-z0-9-]+$`);
- validates requirements `headers.request_payment` uses canonical casing for `X-PAYMENT` and `X402-Payment`;
- validates requirements `headers.request_payment` values are lexicographically sorted;
- validates requirements `platform_fee.fee_bps` is numeric and non-negative;
- validates requirements `platform_fee.fee_bps` is capped at `<=10000`;
- validates requirements `platform_fee.applies_to=paid_interactions_only`;
- validates requirements `amount_policy` exposes payer-autonomy semantics (`agent_self_assessed_fair_value`, `paid_interactions_only`);
- validates requirements `amount_policy.statement` explicitly includes paid-interactions wording;
- validates requirements `amount_policy.statement` includes fair-value wording (`fair`);
- validates requirements `amount_policy.statement` includes agent-decision/payment wording (`decide`, `pay`);
- validates requirements `amount_policy.statement` starts with canonical prefix (`Agents`).
- validates requirements `accepts[0].network` is trimmed (no leading/trailing whitespace);
- validates requirements `accepts[0].asset` is trimmed (no leading/trailing whitespace);
- validates requirements `accepts[0].max_amount` is numeric;
- validates requirements `accepts[0].max_amount` is positive (`>0`);
- validates requirements `accepts[0].pay_to` is trimmed (no leading/trailing whitespace);
- validates x402 mode parity between `/v1/policy` and `/v1/billing/x402/requirements`;
- validates `POST /v1/billing/x402/verify` returns `402 + PAYMENT-REQUIRED` when proof is missing;
- validates `GET /v1/billing/pricing` includes `platform_fee_policy` and x402 fee policy parity with requirements;
- validates `GET /v1/billing/pricing` exposes payer-autonomy policy metadata for paid interactions;
- validates pricing payer-autonomy `statement` includes paid-interactions wording for top-level and x402 nested policy;
- validates payer-autonomy `statement` parity between requirements amount policy, pricing policy, and policy endpoint (including x402 nested policy);
- validates `PAYMENT-REQUIRED` challenge payload is valid JSON with `protocol=x402` and non-empty requirements/verify/pricing links;
- validates `PAYMENT-REQUIRED.x402_version` exists and is numeric;
- validates `PAYMENT-REQUIRED.x402_version` is positive (`>0`);
- validates `PAYMENT-REQUIRED.headers.challenge=PAYMENT-REQUIRED` for challenge-header consistency;
- validates `PAYMENT-REQUIRED.headers.challenge` is trim-normalized and uppercase before token equality check;
- validates `PAYMENT-REQUIRED.headers.response_receipt=X-PAYMENT-RESPONSE` for challenge-header consistency;
- validates `PAYMENT-REQUIRED.headers.response_receipt` is trim-normalized and uppercase before token equality check;
- validates challenge `headers.request_payment` list is present and non-empty;
- validates challenge `headers.request_payment` values are trim-normalized;
- validates challenge `headers.request_payment` values are non-empty;
- validates challenge `headers.request_payment` values match header-token policy (`^[A-Za-z0-9-]+$`);
- validates challenge `headers.request_payment` uses canonical casing for `X-PAYMENT` and `X402-Payment`;
- validates challenge `headers.request_payment` values are lexicographically sorted;
- validates challenge `headers.request_payment` list length is at least 2;
- validates challenge `headers.request_payment` values are unique (no duplicates);
- validates challenge `headers.request_payment` set exactly matches requirements `headers.request_payment`;
- validates challenge `headers.request_payment` order matches requirements `headers.request_payment` order;
- validates challenge `headers.request_payment` includes `X-PAYMENT`;
- validates challenge `headers.request_payment` includes `X402-Payment`;
- validates challenge `links.verify` equals canonical verify path (`/topos/api/v1/billing/x402/verify`);
- validates challenge `links.verify` stays within `/topos/api/v1/` namespace scope;
- validates challenge `links.verify` is normalized (no query string);
- validates challenge `verify_url` (when present) equals canonical verify path;
- validates challenge `links.requirements` equals canonical requirements path (`/topos/api/v1/billing/x402/requirements`);
- validates challenge `links.requirements` stays within `/topos/api/v1/` namespace scope;
- validates challenge `links.requirements` is normalized (no query string);
- validates challenge `links.pricing` equals canonical pricing path (`/topos/api/v1/billing/pricing`);
- validates challenge `links.pricing` stays within `/topos/api/v1/` namespace scope;
- validates challenge `links.pricing` is normalized (no query string);
- validates challenge `accepts[0]` (`network`,`asset`,`max_amount`,`pay_to`) matches requirements `accepts[0]`;
- validates `PAYMENT-REQUIRED.resource` echoes the requested verify resource path;
- validates `PAYMENT-REQUIRED.resource` stays within `/topos/api/v1/` namespace scope;
- validates `PAYMENT-REQUIRED.resource` is normalized (no query string);
- validates `PAYMENT-REQUIRED.mode` matches requirements `data.mode`;
- validates `PAYMENT-REQUIRED.platform_fee.fee_bps` matches requirements `platform_fee.fee_bps`;
- validates `PAYMENT-REQUIRED.platform_fee.fee_bps` is capped at `<=10000`;
- validates `PAYMENT-REQUIRED.platform_fee.applies_to=paid_interactions_only`;
- validates `PAYMENT-REQUIRED.accepts[0]` includes `network`, `asset`, `max_amount`, `pay_to`;
- validates `PAYMENT-REQUIRED.accepts[0].network` is trimmed (no leading/trailing whitespace);
- validates `PAYMENT-REQUIRED.accepts[0].asset` is trimmed (no leading/trailing whitespace);
- validates `PAYMENT-REQUIRED.accepts[0].max_amount` is numeric;
- validates `PAYMENT-REQUIRED.accepts[0].max_amount` is positive (`>0`);
- validates `PAYMENT-REQUIRED.accepts[0].pay_to` is trimmed (no leading/trailing whitespace);
- validates missing-proof verify response includes non-empty `data.mode` and `data.reason`;
- validates missing-proof verify response includes `data.platform_fee` with numeric non-negative `fee_bps`, `applied=false`, `applies_to=paid_interactions_only`;
- validates missing-proof verify response caps `data.platform_fee.fee_bps` at `<=10000`;
- validates `POST /v1/billing/x402/verify` returns `200` when `PAYMENT-SIGNATURE` is supplied.
- validates success verify response includes non-empty `data.mode` and `data.reason`.
- validates success verify response includes `data.platform_fee` with numeric non-negative `fee_bps`, `applied=true`, `applies_to=paid_interactions_only`.
- validates success verify response caps `data.platform_fee.fee_bps` at `<=10000`.
- Troubleshooting/manual examples: `shipinfo-agent-kit/docs/X402_PROTOCOL.md`.
- `release_gate.sh` prints a final x402 contract-scope summary line after smoke checks.
- For requirements-header troubleshooting, use quick references in `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md` and `shipinfo-agent-kit/docs/VERIFY.md`.

If report status is `fail`, list failing checks quickly:

```bash
bash scripts/agents/release_report_fail_checks.sh
STRICT=1 bash scripts/agents/release_report_fail_checks.sh
BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api \
  bash shipinfo-agent-kit/scripts/release_report.sh && STRICT=1 bash scripts/agents/release_report_fail_checks.sh
```

Note:
- These helper commands are mirrored in `shipinfo-agent-kit/docs/VERIFY.md` quick section.
- Gate-output expectation examples (including x402 contract-scope summary line) are maintained in `shipinfo-agent-kit/docs/VERIFY.md`.

Validate report shape:

```bash
REPORT_FILE=shipinfo-agent-kit/reports/release_report_latest.json \
  bash shipinfo-agent-kit/scripts/validate_release_report.sh
```
