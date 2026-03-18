# Verify Agent Kit

## Quick References

Docs index:
- `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md`
- `shipinfo-agent-kit/docs/RELEASE_REPORT.md`
- `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md`
- `shipinfo-agent-kit/docs/X402_PROTOCOL.md`
- x402 manual curl examples: `shipinfo-agent-kit/docs/X402_PROTOCOL.md` (Manual verify examples section).
- x402 expected verify fields (`accepted`, `mode`, `reason`): `shipinfo-agent-kit/docs/X402_PROTOCOL.md` (Behavior section).
- x402 malformed challenge troubleshooting: `shipinfo-agent-kit/docs/X402_PROTOCOL.md` (Troubleshooting section).
- x402 challenge `accepts[0]` contract:
  - `x402_smoke.sh` validates `network`, `asset`, `max_amount`, `pay_to` in `PAYMENT-REQUIRED` payload.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.accepts[0].network` is trimmed.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.accepts[0].asset` is trimmed.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.accepts[0].max_amount` is numeric.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.accepts[0].max_amount` is positive (`>0`).
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.accepts[0].pay_to` is trimmed.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.accepts[0]` parity with requirements `accepts[0]`.
- x402 platform fee contract:
  - `x402_smoke.sh` validates requirements `platform_fee.fee_bps` is numeric and non-negative.
  - `x402_smoke.sh` validates `platform_fee.fee_bps` upper bound (`<=10000`) across requirements/challenge/pricing/verify.
  - `x402_smoke.sh` validates requirements `platform_fee.applies_to=paid_interactions_only`.
  - `x402_smoke.sh` validates pricing `platform_fee_policy` and x402 fee policy parity with requirements.
  - `x402_smoke.sh` validates challenge `platform_fee.fee_bps` parity with requirements.
  - `x402_smoke.sh` validates challenge `platform_fee.applies_to=paid_interactions_only`.
- x402 payer-autonomy contract:
  - `x402_smoke.sh` validates policy payer-autonomy metadata (`pricing_principle=agent_self_assessed_fair_value`, `scope=paid_interactions_only`).
  - `x402_smoke.sh` validates policy payer-autonomy `statement` explicitly includes paid-interactions wording.
  - `x402_smoke.sh` validates pricing payer-autonomy metadata for paid interactions.
  - `x402_smoke.sh` validates pricing payer-autonomy `statement` includes paid-interactions wording (top-level and x402 nested).
  - `x402_smoke.sh` validates requirements `amount_policy` payer-autonomy semantics.
  - `x402_smoke.sh` validates requirements `amount_policy.statement` includes paid-interactions wording.
  - `x402_smoke.sh` validates requirements `amount_policy.statement` includes fair-value wording (`fair`).
  - `x402_smoke.sh` validates requirements `amount_policy.statement` includes agent-decision/payment wording (`decide`, `pay`).
  - `x402_smoke.sh` validates requirements `amount_policy.statement` starts with canonical prefix (`Agents`).
  - `x402_smoke.sh` validates payer-autonomy `statement` parity across requirements/pricing/policy (including x402 nested pricing/policy blocks).
- payer-autonomy docs coverage check (key platform specs):
  - `grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md`
- runtime + docs combined one-liner:
  - `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh && grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md`
- helper script for the same combined check:
  - `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh`
- Canonical maintenance readiness command: `scripts/agents/payer_autonomy_readiness.sh` (expect `payer_autonomy_readiness: pass`).
- Same two-step payer-autonomy readiness flow is mirrored in `shipinfo-agent-kit/docs/RELEASE_REPORT.md` (Quick References).
- Final closure one-liner is mirrored in `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md` (`payer_autonomy_readiness.sh && ops_health_status.sh`).
- Maintenance cadence bridge is mirrored in `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md` (maintenance-start payer-autonomy readiness probe note).
- Maintenance one-liner: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh`.
- Recommended maintenance cadence: run the maintenance one-liner daily during post-rollout operations.
- Recommended maintenance guard-chain cadence: run `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh` daily.
- Expected maintenance chain outputs: `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Drift reminder: include `bash scripts/agents/cron_agent_contract_guard.sh` in maintenance routines to detect contract regressions early.
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
- x402 challenge mode parity:
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.mode` matches requirements `data.mode`.
- x402 challenge links contract:
  - `x402_smoke.sh` validates non-empty challenge links for requirements/verify/pricing.
  - `x402_smoke.sh` validates challenge `links.verify` canonical path (`/topos/api/v1/billing/x402/verify`).
  - `x402_smoke.sh` validates challenge `links.verify` namespace scope (`/topos/api/v1/`).
  - `x402_smoke.sh` validates challenge `links.verify` has no query string.
  - `x402_smoke.sh` validates challenge `verify_url` (when present) canonical path (`/topos/api/v1/billing/x402/verify`).
  - `x402_smoke.sh` validates challenge `links.requirements` canonical path (`/topos/api/v1/billing/x402/requirements`).
  - `x402_smoke.sh` validates challenge `links.requirements` namespace scope (`/topos/api/v1/`).
  - `x402_smoke.sh` validates challenge `links.requirements` has no query string.
  - `x402_smoke.sh` validates challenge `links.pricing` canonical path (`/topos/api/v1/billing/pricing`).
  - `x402_smoke.sh` validates challenge `links.pricing` namespace scope (`/topos/api/v1/`).
  - `x402_smoke.sh` validates challenge `links.pricing` has no query string.
- x402 challenge resource echo-contract:
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.resource` equals requested verify resource path.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.resource` namespace scope (`/topos/api/v1/`).
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.resource` has no query string.
- x402 challenge version contract:
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.x402_version` exists and is numeric.
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.x402_version` is positive (`>0`).
- x402 challenge header consistency:
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.headers.challenge=PAYMENT-REQUIRED`.
  - `x402_smoke.sh` validates challenge `headers.challenge` is trim-normalized and uppercase.
- x402 challenge response-receipt consistency:
  - `x402_smoke.sh` validates `PAYMENT-REQUIRED.headers.response_receipt=X-PAYMENT-RESPONSE`.
  - `x402_smoke.sh` validates challenge `headers.response_receipt` is trim-normalized and uppercase.
- x402 challenge request-payment header list:
  - `x402_smoke.sh` validates challenge `headers.request_payment` list is present and non-empty.
  - `x402_smoke.sh` validates challenge `headers.request_payment` values are trim-normalized.
  - `x402_smoke.sh` validates challenge `headers.request_payment` values are non-empty.
  - `x402_smoke.sh` validates challenge `headers.request_payment` values match header-token policy (`^[A-Za-z0-9-]+$`).
  - `x402_smoke.sh` validates challenge `headers.request_payment` uses canonical casing for `X-PAYMENT` and `X402-Payment`.
  - `x402_smoke.sh` validates challenge `headers.request_payment` values are lexicographically sorted.
  - `x402_smoke.sh` validates challenge `headers.request_payment` length is at least 2.
  - `x402_smoke.sh` validates challenge `headers.request_payment` contains unique values (no duplicates).
  - `x402_smoke.sh` validates challenge `headers.request_payment` set matches requirements `headers.request_payment`.
  - `x402_smoke.sh` validates challenge `headers.request_payment` order matches requirements order.
  - `x402_smoke.sh` validates challenge `headers.request_payment` includes `X-PAYMENT`.
  - `x402_smoke.sh` validates challenge `headers.request_payment` includes `X402-Payment`.
- x402 requirements header contract:
  - `x402_smoke.sh` validates `headers.challenge=PAYMENT-REQUIRED` and `headers.response_receipt=X-PAYMENT-RESPONSE`.
  - `x402_smoke.sh` validates requirements `headers.challenge` is trim-normalized and uppercase.
  - `x402_smoke.sh` validates requirements `headers.response_receipt` is trim-normalized and uppercase.
- x402 requirements request-payment header list:
  - `x402_smoke.sh` validates non-empty `headers.request_payment` array with `X-PAYMENT` and `X402-Payment`.
  - `x402_smoke.sh` validates requirements `headers.request_payment` values are trim-normalized.
  - `x402_smoke.sh` validates requirements `headers.request_payment` has no duplicate values.
  - `x402_smoke.sh` validates requirements `headers.request_payment` values are non-empty.
  - `x402_smoke.sh` validates requirements `headers.request_payment` values match header-token policy (`^[A-Za-z0-9-]+$`).
  - `x402_smoke.sh` validates requirements `headers.request_payment` uses canonical casing for `X-PAYMENT` and `X402-Payment`.
  - `x402_smoke.sh` validates requirements `headers.request_payment` values are lexicographically sorted.
  - `x402_smoke.sh` validates requirements `accepts[0].network` is trimmed.
  - `x402_smoke.sh` validates requirements `accepts[0].asset` is trimmed.
  - `x402_smoke.sh` validates requirements `accepts[0].max_amount` is numeric.
  - `x402_smoke.sh` validates requirements `accepts[0].max_amount` is positive (`>0`).
  - `x402_smoke.sh` validates requirements `accepts[0].pay_to` is trimmed.
- x402 challenge debug command:
  - `X402_SMOKE_DEBUG=1 BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh`
- x402 request-resource input guard:
  - `x402_smoke.sh` validates `REQUEST_RESOURCE` is under `/topos/api/v1/` and has no query/fragment/whitespace.
- x402 OpenAPI/discoverability registry checklist: `shipinfo-agent-kit/docs/MCP_REGISTRY_PUBLISH.md`.
- release gate x402 summary line:
  - after `release_gate.sh`, expect `[gate] x402 contract scope: ...` before `release_gate: pass`.
- Quick references consistency check:
  - `grep -n '^## Quick References' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md shipinfo-agent-kit/docs/RELEASE_REPORT.md shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md`
- Quick triage-line consistency check:
  - `grep -n 'Quickest triage path:' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md`
- Docs audit chain:
  - `grep -n '^## Quick References' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md shipinfo-agent-kit/docs/RELEASE_REPORT.md shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md && grep -n 'Quickest triage path:' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md`
- Changelog hygiene note:
  - Include 1-2 docs-audit output snippets in sprint changelog blocks where docs references were updated.
- Sprint tracker hygiene check:
  - `test \"$(grep -c '^Status: in_progress$' AGENT_PLATFORM_SPRINTS.md)\" -eq 1 && echo 'in_progress_count=1'`
- Docs + sprint tracker combined check:
  - `grep -n '^## Quick References' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md shipinfo-agent-kit/docs/RELEASE_REPORT.md shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md && grep -n 'Quickest triage path:' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md && test \"$(grep -c '^Status: in_progress$' AGENT_PLATFORM_SPRINTS.md)\" -eq 1 && echo 'in_progress_count=1'`
- Before changing sprint statuses in `AGENT_PLATFORM_SPRINTS.md`, run `Docs + sprint tracker combined check`.

Local checks:

1. Syntax:
- node --check shipinfo-agent-kit/packages/sdk-js/src/index.js
- node --check shipinfo-agent-kit/packages/mcp-server/src/server.js
- python3 -m py_compile shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/client.py shipinfo-agent-kit/packages/sdk-py/shipinfo_sdk/errors.py
- bash -n shipinfo-agent-kit/scripts/e2e_smoke.sh
- bash -n shipinfo-agent-kit/scripts/x402_smoke.sh
- bash -n shipinfo-agent-kit/scripts/check_registry_links.sh
- bash -n shipinfo-agent-kit/scripts/check_registry_capabilities_alignment.sh
- bash -n shipinfo-agent-kit/scripts/mcp_smoke.sh
- bash -n shipinfo-agent-kit/scripts/mcp_contract_matrix.sh
- bash -n shipinfo-agent-kit/scripts/e2e_auth_fixture.sh
- bash -n shipinfo-agent-kit/scripts/validate_release_report.sh
- bash -n scripts/agents/smoke_agent_platform.sh
- bash -n scripts/agents/ops_agent_platform_handoff.sh
- bash -n scripts/agents/ops_health_snapshot.sh
- bash -n scripts/agents/ops_health_status.sh
- bash -n scripts/agents/release_artifact_paths.sh
- bash -n scripts/agents/release_artifact_paths_json.sh
- bash -n scripts/agents/validate_release_artifact_paths.sh
- bash -n scripts/agents/validate_release_artifact_paths_json.sh
- bash -n scripts/agents/release_report_fail_checks.sh
- bash -n shipinfo-agent-kit/scripts/release_gate.sh

2. Registry and contract checks:
- bash shipinfo-agent-kit/scripts/check_registry_links.sh
- BASE_URL=https://shipinfo.net/topos/api STRICT=1 bash shipinfo-agent-kit/scripts/check_registry_capabilities_alignment.sh
- BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/check_contract_regression.sh

3. Live API e2e smoke:
- BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/e2e_smoke.sh

3.1 x402 smoke:
- BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh

4. MCP smoke:
- SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/mcp_smoke.sh
- SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/mcp_contract_matrix.sh

5. Agent platform smoke:
- BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/smoke_agent_platform.sh

6. Auth fixture smoke:
- bash shipinfo-agent-kit/scripts/e2e_auth_fixture.sh

7. Release report schema check:
- REPORT_FILE=shipinfo-agent-kit/reports/release_report_latest.json bash shipinfo-agent-kit/scripts/validate_release_report.sh

8. Full release gate:
- BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_gate.sh

9. Ops handoff chain:
- BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash scripts/agents/ops_agent_platform_handoff.sh
- Runbook: `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md`

10. Ops health snapshot:
- bash scripts/agents/ops_health_snapshot.sh
- SNAPSHOT_FILE=/var/www/shipinfo.net/topos/logs/agent_platform_health_snapshot.json bash scripts/agents/validate_ops_health_snapshot.sh
- bash scripts/agents/ops_health_status.sh

Optional authenticated run:
- SHIPINFO_API_KEY=... BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/e2e_smoke.sh
- SHIPINFO_API_KEY=... BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_gate.sh

Scheduled CI note:
- On `schedule` runs, workflow uploads `shipinfo-agent-kit-ops-health-snapshot` artifact.
- In workflow job summary, confirm `Manifest integrity checks` lines are all `ok`.
- In workflow job summary, confirm line `Artifact helper chain check present: release_artifact_chain` exists.
- If workflow fails, run `bash scripts/agents/release_report_fail_checks.sh` locally for quick reproduction of failing check names.
- Local helper: `bash scripts/agents/release_artifact_paths.sh`
- Local helper JSON: `bash scripts/agents/release_artifact_paths_json.sh`
- Local helper validation: `bash scripts/agents/validate_release_artifact_paths.sh`
- Local helper JSON validation: `bash scripts/agents/validate_release_artifact_paths_json.sh`
- Quick chain: `bash scripts/agents/release_artifact_paths.sh && bash scripts/agents/release_artifact_paths_json.sh && bash scripts/agents/validate_release_artifact_paths.sh && bash scripts/agents/validate_release_artifact_paths_json.sh`
- Release report fail-check helper: `bash scripts/agents/release_report_fail_checks.sh`
- Release report + fail-check quick command: `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_report.sh && bash scripts/agents/release_report_fail_checks.sh`
- Combined quick status: `bash scripts/agents/release_report_fail_checks.sh && bash scripts/agents/ops_health_status.sh`
- Quickest triage path: `STRICT=1 bash scripts/agents/release_report_fail_checks.sh && bash scripts/agents/ops_health_status.sh`
- If report file is missing, fail-check helper exits with error; regenerate report first via `bash shipinfo-agent-kit/scripts/release_report.sh`.
- In strict mode (`STRICT=1`), fail-check helper is expected to return non-zero when any check is failing.
- See strict-triage reproduction command in `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md`.
- Pre-publish quick preflight: `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_gate.sh && bash scripts/agents/ops_health_status.sh`
- x402 mode probe:
  - `BASE_URL=https://shipinfo.net/topos/api; curl -sS \"$BASE_URL/v1/policy\" | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo \"policy_x402_mode=\".($j[\"data\"][\"payment_protocols\"][\"x402\"][\"mode\"] ?? \"n/a\").\"\\n\";' && curl -sS \"$BASE_URL/v1/billing/x402/requirements\" | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo \"requirements_x402_mode=\".($j[\"data\"][\"mode\"] ?? \"n/a\").\"\\n\";'`
- x402 mode parity enforcement:
  - `x402_smoke.sh` asserts both endpoints expose allowed mode values and that policy/requirements modes match.
- x402 missing-proof response contract enforcement:
  - `x402_smoke.sh` asserts non-empty `data.mode` and `data.reason` on verify responses without payment proof.
- x402 success response contract enforcement:
  - `x402_smoke.sh` asserts non-empty `data.mode` and `data.reason` on verify responses with `PAYMENT-SIGNATURE`.
  - `x402_smoke.sh` asserts `data.platform_fee` contract on verify responses:
  - `fee_bps` numeric non-negative, `applied=false` for missing-proof and `applied=true` for success, `applies_to=paid_interactions_only`.
- x402 verify fields probe:
  - `BASE_URL=https://shipinfo.net/topos/api; curl -sS -H 'Content-Type: application/json' -X POST \"$BASE_URL/v1/billing/x402/verify\" --data '{\"resource\":\"/topos/api/v1/vessels/lookup\"}' | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo \"accepted=\".json_encode($j[\"data\"][\"accepted\"] ?? null).\" mode=\".($j[\"data\"][\"mode\"] ?? \"n/a\").\" reason=\".($j[\"data\"][\"reason\"] ?? \"n/a\").\"\\n\";'`
- x402 verify success probe:
  - `BASE_URL=https://shipinfo.net/topos/api; curl -sS -H 'Content-Type: application/json' -H 'PAYMENT-SIGNATURE: stub-signature' -X POST \"$BASE_URL/v1/billing/x402/verify\" --data '{\"resource\":\"/topos/api/v1/vessels/lookup\"}' | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo \"accepted=\".json_encode($j[\"data\"][\"accepted\"] ?? null).\" mode=\".($j[\"data\"][\"mode\"] ?? \"n/a\").\" reason=\".($j[\"data\"][\"reason\"] ?? \"n/a\").\"\\n\";'`
- x402 verify combined chain:
  - `BASE_URL=https://shipinfo.net/topos/api; curl -sS -H 'Content-Type: application/json' -X POST \"$BASE_URL/v1/billing/x402/verify\" --data '{\"resource\":\"/topos/api/v1/vessels/lookup\"}' | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo \"missing_proof accepted=\".json_encode($j[\"data\"][\"accepted\"] ?? null).\" mode=\".($j[\"data\"][\"mode\"] ?? \"n/a\").\" reason=\".($j[\"data\"][\"reason\"] ?? \"n/a\").\"\\n\";' && curl -sS -H 'Content-Type: application/json' -H 'PAYMENT-SIGNATURE: stub-signature' -X POST \"$BASE_URL/v1/billing/x402/verify\" --data '{\"resource\":\"/topos/api/v1/vessels/lookup\"}' | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo \"with_signature accepted=\".json_encode($j[\"data\"][\"accepted\"] ?? null).\" mode=\".($j[\"data\"][\"mode\"] ?? \"n/a\").\" reason=\".($j[\"data\"][\"reason\"] ?? \"n/a\").\"\\n\";'`
- After any billing capability/path update, run `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh`.
