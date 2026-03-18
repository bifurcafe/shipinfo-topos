# Release Checklist

## Quick References

Start point:
- Review `shipinfo-agent-kit/docs/VERIFY.md` docs index before release review.
- Run quick references consistency check:
  - `grep -n '^## Quick References' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md shipinfo-agent-kit/docs/RELEASE_REPORT.md shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md`
- Run pre-release docs audit triage check:
  - `grep -n 'Quickest triage path:' shipinfo-agent-kit/docs/VERIFY.md shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md`
- Full docs audit chain is defined in `shipinfo-agent-kit/docs/VERIFY.md` (`Docs audit chain`).
- For docs updates, include 1-2 docs-audit command output snippets in the related sprint changelog block.
- Sprint status hygiene check:
  - `test \"$(grep -c '^Status: in_progress$' AGENT_PLATFORM_SPRINTS.md)\" -eq 1 && echo 'in_progress_count=1'`
- Combined docs + sprint tracker check is defined in `shipinfo-agent-kit/docs/VERIFY.md` (`Docs + sprint tracker combined check`).

1. Validate syntax and local contracts.
- bash shipinfo-agent-kit/scripts/release_gate.sh
- In gate output, confirm line `[gate] x402 contract scope: ...` appears before `release_gate: pass`.

2. Confirm registry links resolve publicly.
- bash shipinfo-agent-kit/scripts/check_registry_links.sh

3. Confirm live API e2e smoke.
- BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/e2e_smoke.sh

3.1 Confirm x402 smoke.
- BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh
- x402 behavior reference: `shipinfo-agent-kit/docs/X402_PROTOCOL.md`
- For malformed `PAYMENT-REQUIRED` challenge headers, use `shipinfo-agent-kit/docs/X402_PROTOCOL.md` troubleshooting section.
- Validate x402 mode env before release: `AGENT_X402_MODE=disabled|optional|required`.
- Re-run x402 smoke after any policy/payment-protocol config changes.
- `x402_smoke.sh` also validates policy/requirements mode parity for x402.
- Manual curl spot-check (optional): verify body `data.accepted`, `data.mode`, `data.reason` on `/v1/billing/x402/verify`.
- Operator one-liner for the same fields is in `shipinfo-agent-kit/docs/VERIFY.md` (`x402 verify fields probe`).
- Success-case probe (`PAYMENT-SIGNATURE`) is in `shipinfo-agent-kit/docs/VERIFY.md` (`x402 verify success probe`).
- Combined missing-proof + success probe chain is in `shipinfo-agent-kit/docs/VERIFY.md` (`x402 verify combined chain`).
- `x402_smoke.sh` now contract-checks non-empty `data.mode`/`data.reason` for both missing-proof and success verify responses.
- `x402_smoke.sh` also validates verify-response `data.platform_fee` contract (`fee_bps`, `applied`, `applies_to`) for missing-proof and success paths.
- `x402_smoke.sh` also validates requirements header contract (`headers.challenge=PAYMENT-REQUIRED`, `headers.response_receipt=X-PAYMENT-RESPONSE`).
- `x402_smoke.sh` also validates requirements `headers.challenge` trim-normalization and uppercase.
- `x402_smoke.sh` also validates requirements `headers.response_receipt` trim-normalization and uppercase.
- `x402_smoke.sh` also validates requirements request-payment header list (`headers.request_payment`) is non-empty and contains `X-PAYMENT` + `X402-Payment`.
- `x402_smoke.sh` also validates requirements `headers.request_payment` values are trim-normalized.
- `x402_smoke.sh` also validates requirements `headers.request_payment` has no duplicate values.
- `x402_smoke.sh` also validates requirements `headers.request_payment` values are non-empty.
- `x402_smoke.sh` also validates requirements `headers.request_payment` values match header-token policy (`^[A-Za-z0-9-]+$`).
- `x402_smoke.sh` also validates requirements `headers.request_payment` uses canonical casing for `X-PAYMENT` and `X402-Payment`.
- `x402_smoke.sh` also validates requirements `headers.request_payment` values are lexicographically sorted.
- `x402_smoke.sh` also validates requirements `platform_fee.fee_bps` numeric non-negative contract.
- `x402_smoke.sh` also validates `platform_fee.fee_bps` upper bound (`<=10000`) across requirements/challenge/pricing/verify.
- `x402_smoke.sh` also validates requirements `platform_fee.applies_to=paid_interactions_only`.
- `x402_smoke.sh` also validates policy/pricing/requirements payer-autonomy metadata (`agent_self_assessed_fair_value`, `paid_interactions_only`).
- `x402_smoke.sh` also validates payer-autonomy `statement` wording explicitly scopes to paid interactions (policy/pricing/requirements and x402 nested pricing policy).
- `x402_smoke.sh` also validates payer-autonomy `statement` keeps fair-value wording (`fair`) in requirements amount policy.
- `x402_smoke.sh` also validates payer-autonomy `statement` keeps agent-decision/payment wording (`decide`, `pay`) in requirements amount policy.
- `x402_smoke.sh` also validates payer-autonomy `statement` starts with canonical prefix (`Agents`) in requirements amount policy.
- `x402_smoke.sh` also validates payer-autonomy `statement` parity across requirements/pricing/policy (including x402 nested pricing/policy blocks).
- Run payer-autonomy docs coverage one-liner from `shipinfo-agent-kit/docs/VERIFY.md` to confirm wording is present across key specs before release.
- Run VERIFY combined one-liner (x402 smoke + docs coverage grep) before final release sign-off.
- Or run helper script: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh`.
- Canonical maintenance readiness command: `scripts/agents/payer_autonomy_readiness.sh` (expect `payer_autonomy_readiness: pass`).
- Final acceptance criterion: release sign-off is blocked unless `scripts/agents/payer_autonomy_readiness.sh` ends with `payer_autonomy_readiness: pass`.
- Final rollout one-liner (runbook): `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh`.
- Maintenance bridge: use `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` maintenance-start note to keep recurring payer-autonomy readiness probes in post-rollout windows, and pair with `bash scripts/agents/ops_health_status.sh`.
- Recommended maintenance cadence: run `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh` daily.
- Recommended maintenance guard-chain cadence: run `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh` daily.
- Expected maintenance chain outputs: `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Drift reminder: run `bash scripts/agents/cron_agent_contract_guard.sh` in maintenance routines to catch contract drift early.
- Maintenance guard chain: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh`
- Default steady-state validation path: run the maintenance guard chain as the primary post-rollout audit flow.
- Preferred command order: readiness -> heartbeat -> drift guard.
- Outcome confirmation: this order should produce `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Core context bridge: use `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (core policy/spec context refresh list) when validating payer-autonomy policy wording in maintenance cycles.
- Baseline marker bridge: use `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Maintenance baseline marker`) for canonical maintenance command set.
- Steady-state bridge: use `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Steady-state note`) for current operational mode.
- Steady-state summary bridge: use `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Steady-state summary`) for compact maintenance directives.
- Command-surface snapshot bridge: use `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Maintenance command-surface snapshot`) for current command set baseline.
- Snapshot-to-audit rule: after reviewing `Maintenance command-surface snapshot`, execute `Combined maintenance audit chain`.
- Maintenance entry point: start from `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` -> `Steady-state summary`.
- Entry-to-chain rule: from this entry point, execute `Combined maintenance audit chain` as default next step.
- Audit chain bridge: see `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Combined maintenance audit chain`) for daily policy+ops validation.
- Maintenance readiness recap: paid-only fair-value policy (`agent_self_assessed_fair_value`, `paid_interactions_only`) with daily guard-chain and expected outputs `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`.
- Maintenance flow recap: from `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md` (`Steady-state summary`) run `Combined maintenance audit chain` and confirm outputs (`payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`).
- Flow recap anchor reminder bridge: keep recap wording aligned with OPS runbook `Flow recap anchor drift reminder`.
- Reverse bridge count guard bridge: keep the reminder-bridge line exactly one per file and align with OPS runbook `Reverse bridge note`.
- `x402_smoke.sh` also validates requirements `accepts[0].network` is trimmed.
- `x402_smoke.sh` also validates requirements `accepts[0].asset` is trimmed.
- `x402_smoke.sh` also validates requirements `accepts[0].max_amount` is numeric.
- `x402_smoke.sh` also validates requirements `accepts[0].max_amount` is positive (`>0`).
- `x402_smoke.sh` also validates requirements `accepts[0].pay_to` is trimmed.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.mode` parity with requirements `data.mode`.
- `x402_smoke.sh` also validates non-empty challenge links for requirements/verify/pricing.
- `x402_smoke.sh` also validates challenge `links.verify` canonical path (`/topos/api/v1/billing/x402/verify`).
- `x402_smoke.sh` also validates challenge `links.verify` namespace scope (`/topos/api/v1/`).
- `x402_smoke.sh` also validates challenge `links.verify` normalization (no query string).
- `x402_smoke.sh` also validates challenge `verify_url` (when present) canonical path (`/topos/api/v1/billing/x402/verify`).
- `x402_smoke.sh` also validates challenge `links.requirements` canonical path (`/topos/api/v1/billing/x402/requirements`).
- `x402_smoke.sh` also validates challenge `links.requirements` namespace scope (`/topos/api/v1/`).
- `x402_smoke.sh` also validates challenge `links.requirements` normalization (no query string).
- `x402_smoke.sh` also validates challenge `links.pricing` canonical path (`/topos/api/v1/billing/pricing`).
- `x402_smoke.sh` also validates challenge `links.pricing` namespace scope (`/topos/api/v1/`).
- `x402_smoke.sh` also validates challenge `links.pricing` normalization (no query string).
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.resource` parity with requested verify resource path.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.resource` namespace scope (`/topos/api/v1/`).
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.resource` normalization (no query string).
- `x402_smoke.sh` also validates numeric `PAYMENT-REQUIRED.x402_version`.
- `x402_smoke.sh` also validates positive (`>0`) `PAYMENT-REQUIRED.x402_version`.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.headers.challenge=PAYMENT-REQUIRED`.
- `x402_smoke.sh` also validates challenge `headers.challenge` trim-normalization and uppercase.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.headers.response_receipt=X-PAYMENT-RESPONSE`.
- `x402_smoke.sh` also validates challenge `headers.response_receipt` trim-normalization and uppercase.
- `x402_smoke.sh` also validates challenge `headers.request_payment` list is present and non-empty.
- `x402_smoke.sh` also validates challenge `headers.request_payment` values are trim-normalized.
- `x402_smoke.sh` also validates challenge `headers.request_payment` values are non-empty.
- `x402_smoke.sh` also validates challenge `headers.request_payment` values match header-token policy (`^[A-Za-z0-9-]+$`).
- `x402_smoke.sh` also validates challenge `headers.request_payment` uses canonical casing for `X-PAYMENT` and `X402-Payment`.
- `x402_smoke.sh` also validates challenge `headers.request_payment` values are lexicographically sorted.
- `x402_smoke.sh` also validates challenge `platform_fee.fee_bps` parity with requirements.
- `x402_smoke.sh` also validates challenge `platform_fee.applies_to=paid_interactions_only`.
- `x402_smoke.sh` also validates challenge `headers.request_payment` length is at least 2.
- `x402_smoke.sh` also validates challenge `headers.request_payment` values are unique (no duplicates).
- `x402_smoke.sh` also validates challenge `headers.request_payment` set parity with requirements.
- `x402_smoke.sh` also validates challenge `headers.request_payment` order parity with requirements.
- `x402_smoke.sh` also validates challenge `headers.request_payment` includes `X-PAYMENT`.
- `x402_smoke.sh` also validates challenge `headers.request_payment` includes `X402-Payment`.
- `x402_smoke.sh` also validates challenge `accepts[0]` parity with requirements `accepts[0]`.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.accepts[0].network` is trimmed.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.accepts[0].asset` is trimmed.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.accepts[0].max_amount` is numeric.
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.accepts[0].max_amount` is positive (`>0`).
- `x402_smoke.sh` also validates `PAYMENT-REQUIRED.accepts[0].pay_to` is trimmed.
- Optional debug for challenge parsing:
  - `X402_SMOKE_DEBUG=1 BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/x402_smoke.sh`
- `x402_smoke.sh` also validates pricing `platform_fee_policy` and x402 fee policy parity with requirements.
- `x402_smoke.sh` also validates pricing x402 payer-autonomy parity semantics for paid interactions.
- Ensure `REQUEST_RESOURCE` input remains normalized for smoke runs (namespace `/topos/api/v1/`, no query/fragment/whitespace).
- Debug command reference is also listed in `shipinfo-agent-kit/docs/VERIFY.md` quick references (`x402 challenge debug command`).

4. Confirm MCP wrapper smoke.
- SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/mcp_smoke.sh

5. Optional authenticated validation.
- SHIPINFO_API_KEY=<token> BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/e2e_smoke.sh

6. Dry-run package release.
- npm pack --dry-run in packages/sdk-js
- python -m build in packages/sdk-py

7. Trigger CI gate workflow and verify green state.
- verify-agent-kit workflow

8. Run ops handoff chain before/after release windows.
- BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash scripts/agents/ops_agent_platform_handoff.sh
- Runbook: `shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md`

9. Optional scheduled CI note.
- For regular non-secret health checks, add a `schedule` trigger that runs release gate with auth fixture mode.

10. CI summary integrity review (blocking before publish).
- Open workflow `verify-agent-kit` job summary and confirm `### Errors` section is absent.
- If `### Errors` exists, do not publish; fix manifest/report/checksum mismatch first.
- Confirm `x402_smoke` is `ok` in release report checks section (or CI summary checks list).

11. Compare local artifact path helper output with workflow artifacts.
- Run `bash scripts/agents/release_artifact_paths.sh`.
- Confirm paths map to uploaded artifacts:
  - `shipinfo-agent-kit-release-report`
  - `shipinfo-agent-kit-checksums`
  - `shipinfo-agent-kit-release-manifest`
- Expected helper output format:
  - `release_artifacts report=... checksums=... manifest=... registry=...`
  - `validate_release_artifact_paths: pass`

12. Final pre-publish ops heartbeat.
- Run `bash scripts/agents/ops_health_status.sh`.
- Expected: `ops_health_status=ok release_gate=ok contract_guard=ok ...`

13. Optional JSON artifact map for CI/debug pipelines.
- Run `bash scripts/agents/release_artifact_paths_json.sh`.
- Use JSON keys (`report`, `checksums`, `manifest`, `registry`) to wire downstream upload/validation scripts.

14. Run helper-chain before final publish.
- `bash scripts/agents/release_artifact_paths.sh && bash scripts/agents/release_artifact_paths_json.sh && bash scripts/agents/validate_release_artifact_paths.sh && bash scripts/agents/validate_release_artifact_paths_json.sh`
- Expected pass outputs include:
  - `release_artifacts report=... checksums=... manifest=... registry=...`
  - `validate_release_artifact_paths: pass`
  - `validate_release_artifact_paths_json: pass`
- In release report, verify checks are present and `ok`:
  - `release_artifact_paths`
  - `release_artifact_paths_json`
  - `release_artifact_chain`

15. Fast triage of release report failures (if any).
- `bash scripts/agents/release_report_fail_checks.sh`
- Quickest triage path: `STRICT=1 bash scripts/agents/release_report_fail_checks.sh && bash scripts/agents/ops_health_status.sh`
- Optional blocking mode: `STRICT=1 bash scripts/agents/release_report_fail_checks.sh`
- Expected outputs:
  - Normal pass path: `release_report_fail_checks: none`
  - Failure list path: `release_report_fail_checks: check_name_1,check_name_2`
- Optional strict triage gate before publish:
  - `STRICT=1 bash scripts/agents/release_report_fail_checks.sh && bash scripts/agents/ops_health_status.sh`
- Local strict triage reproduction one-liner:
  - `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_report.sh && STRICT=1 bash scripts/agents/release_report_fail_checks.sh`
- Fallback if report file missing:
  - `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_report.sh && bash scripts/agents/release_report_fail_checks.sh`
- Fail-check command details are documented in `shipinfo-agent-kit/docs/RELEASE_REPORT.md`.
- See `shipinfo-agent-kit/docs/VERIFY.md` for quick command section (gate + report + fail-check helpers).
