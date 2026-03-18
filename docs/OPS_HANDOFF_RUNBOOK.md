# Ops Handoff Runbook

## Quick References

- `shipinfo-agent-kit/docs/VERIFY.md`
- `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md`
- `shipinfo-agent-kit/docs/RELEASE_REPORT.md`
- Release-day start point: `shipinfo-agent-kit/docs/RELEASE_CHECKLIST.md` (Start point section).
- Sprint status hygiene check before edits:
  - `test \"$(grep -c '^Status: in_progress$' /var/www/shipinfo.net/topos/AGENT_PLATFORM_SPRINTS.md)\" -eq 1 && echo 'in_progress_count=1'`
- Payer-autonomy readiness helper (paid flows only):
  - `BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/payer_autonomy_readiness.sh`
  - Canonical maintenance readiness command: `scripts/agents/payer_autonomy_readiness.sh`
  - Policy reminder: for paid interactions, agents decide fair value and pay the amount they consider appropriate (`agent_self_assessed_fair_value`, `paid_interactions_only`).
  - Script-catalog pointer: `scripts/agents/CRON.md` (pre-release/incident payer-autonomy readiness probe).
  - Core policy/spec context refresh:
    - `shipinfo_analytics_api.md`
    - `shipinfo_agent_native.md`
    - `maritime_agent_coordination.md`
    - `agent_native_api_quickstart.md`
    - `shipinfo_api_discoverability_spec.md`
    - `agent_hybrid_tier_upgrade.md`
    - `shipinfo_mcp_sdk_release_spec.md`

Primary one-command handoff:

```bash
BASE_URL=https://shipinfo.net/topos/api \
SHIPINFO_API_BASE=https://shipinfo.net/topos/api \
bash scripts/agents/ops_agent_platform_handoff.sh
```

This command runs:
- `shipinfo-agent-kit/scripts/release_gate.sh`
- `scripts/agents/cron_agent_contract_guard.sh`

Logs:
- `logs/agent_platform_handoff.log`
- `logs/agent_contract_guard.log`
- `logs/agent_platform_health_snapshot.json`

Optional auth/admin mode:

```bash
BASE_URL=https://shipinfo.net/topos/api \
SHIPINFO_API_BASE=https://shipinfo.net/topos/api \
SHIPINFO_API_KEY=... \
AGENT_ADMIN_TOKEN=... \
bash scripts/agents/ops_agent_platform_handoff.sh
```

Drift auto-refresh mode (ops-only):

```bash
BASE_URL=https://shipinfo.net/topos/api \
AUTO_REFRESH_ON_DRIFT=1 \
bash scripts/agents/ops_agent_platform_handoff.sh
```

Triage sequence on failure:

1. Check `logs/agent_platform_handoff.log` for first failed stage (`release_gate` or `contract_guard`).
2. If `release_gate` failed, rerun targeted check from the failed stage (registry links, regression, mcp matrix, smoke).
3. If `contract_guard` failed, run:
   - `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/check_contract_regression.sh`
   - `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/check_openapi_regression.sh`
4. For expected API contract changes, refresh baselines explicitly:
   - `BASE_URL=https://shipinfo.net/topos/api OUT_DIR=shipinfo-agent-kit/contracts/baseline bash shipinfo-agent-kit/scripts/capture_contract_snapshot.sh`
   - `BASE_URL=https://shipinfo.net/topos/api OUT_DIR=shipinfo-agent-kit/contracts/baseline bash shipinfo-agent-kit/scripts/capture_openapi_snapshot.sh`
5. Re-run handoff command and confirm `ops_agent_platform_handoff: pass`.

Generate snapshot manually:

```bash
bash scripts/agents/ops_health_snapshot.sh
bash scripts/agents/validate_ops_health_snapshot.sh
bash scripts/agents/ops_health_status.sh
```

Monitoring integration snippet:

```bash
status_line="$(bash /var/www/shipinfo.net/topos/scripts/agents/ops_health_status.sh)"
echo "$status_line"
# Example: push to external monitor as plain-text heartbeat metric.
```

When to run which helper:

- `ops_health_status.sh`: fast one-line heartbeat for cron/monitoring dashboards.
- `ops_health_snapshot.sh`: regenerate full JSON state after handoff/guard updates.
- `validate_ops_health_snapshot.sh`: contract check before relying on snapshot in automation.

`unknown` status interpretation:

- `unknown` usually means snapshot/log file is missing or no matching state line has been written yet.
- First action: run `bash scripts/agents/ops_agent_platform_handoff.sh` once and re-check status.
- If still `unknown`, verify readable files:
  - `logs/agent_platform_handoff.log`
  - `logs/agent_contract_guard.log`
  - `logs/agent_platform_health_snapshot.json`

Fast triage command:

```bash
tail -n 20 /var/www/shipinfo.net/topos/logs/agent_platform_handoff.log
STRICT=1 bash /var/www/shipinfo.net/topos/scripts/agents/release_report_fail_checks.sh
```

Note: in `STRICT=1` mode, `release_report_fail_checks.sh` exits non-zero when at least one check is failing.
Fallback regeneration command before strict triage:
- `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/shipinfo-agent-kit/scripts/release_report.sh`
- Local strict-triage reproduction:
  - `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/shipinfo-agent-kit/scripts/release_report.sh && STRICT=1 bash /var/www/shipinfo.net/topos/scripts/agents/release_report_fail_checks.sh`

Quick artifact existence check:

```bash
bash /var/www/shipinfo.net/topos/scripts/agents/validate_release_artifact_paths.sh
bash /var/www/shipinfo.net/topos/scripts/agents/release_artifact_paths.sh
```

Preflight before manual release window:

```bash
BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api \
bash /var/www/shipinfo.net/topos/shipinfo-agent-kit/scripts/release_gate.sh && \
bash /var/www/shipinfo.net/topos/scripts/agents/ops_health_status.sh
```

Automation gating hint:

- Use `shipinfo-agent-kit/reports/release_report_latest.json` -> `checks[]`.
- Treat any `status=fail` as blocking for publish promotion.
- For quick doc navigation during incidents, start with `shipinfo-agent-kit/docs/VERIFY.md` (docs index section).
- During docs maintenance, run quick triage-line grep from `VERIFY.md` to ensure pointers stay synchronized.
- During release-day prep, run the `Docs audit chain` command from `VERIFY.md`.
- Add 1-2 lines of docs-audit command output snippets into the related `CHANGELOG_AGENT.md` sprint block.
- Before release-day documentation edits, run `Docs + sprint tracker combined check` from `VERIFY.md`.

Combined quick status one-liner:

```bash
bash /var/www/shipinfo.net/topos/scripts/agents/release_report_fail_checks.sh && \
bash /var/www/shipinfo.net/topos/scripts/agents/ops_health_status.sh
```

Final rollout readiness one-liner:

```bash
BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/payer_autonomy_readiness.sh && \
bash /var/www/shipinfo.net/topos/scripts/agents/ops_health_status.sh
```

Maintenance-start note:
- Keep recurring payer-autonomy readiness probe in maintenance windows:
  - `BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/payer_autonomy_readiness.sh`
- Recommended cadence: run `payer_autonomy_readiness.sh && ops_health_status.sh` at least daily during post-rollout maintenance.

Maintenance baseline marker:
- Canonical readiness: `BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/payer_autonomy_readiness.sh`
- Heartbeat: `bash /var/www/shipinfo.net/topos/scripts/agents/ops_health_status.sh`
- Drift guard: `BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/cron_agent_contract_guard.sh`
- Canonical chain: `BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/payer_autonomy_readiness.sh && bash /var/www/shipinfo.net/topos/scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash /var/www/shipinfo.net/topos/scripts/agents/cron_agent_contract_guard.sh`

Steady-state note:
- Platform is operating in post-rollout maintenance mode.
- Keep the daily maintenance guard-chain as the default operational baseline.

Steady-state summary:
- Canonical command: `scripts/agents/payer_autonomy_readiness.sh`
- Daily chain order: readiness -> heartbeat -> drift guard
- Daily chain expectation: `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`

Maintenance command-surface snapshot:
- Canonical readiness: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh`
- Canonical chain: `BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh`
- Policy audit: `grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md`
- Combined audit chain: policy audit + canonical chain
- Expected outputs: `payer_autonomy_readiness: pass`, `ops_health_status=ok`, `contract_guard ok`
- Flow recap anchor drift reminder: quick-doc `Maintenance flow recap` wording must stay anchored to this runbook (`Steady-state summary` -> `Combined maintenance audit chain` -> expected outputs).
- Reverse bridge note: quick-doc files `VERIFY.md`, `RELEASE_CHECKLIST.md`, and `RELEASE_REPORT.md` must keep `Flow recap anchor reminder bridge` line aligned with this reminder.
- Count-guard mirror note: each quick-doc file must keep exactly one `Reverse bridge count guard bridge` line aligned with this runbook maintenance reminder chain.
- Baseline snapshot mismatch triage: if baseline snapshot counters differ from contract (`baseline_header=1`, `draft_header=0`, per quick-doc flow/count bridges=1), stop release flow, run quick-doc/OPS dedupe checks, then re-run canonical snapshot command.
- Stage 8 hardening guardrail: before/after any reliability hardening delta, preserve locked baseline contract (`triage_note_count=1`, `baseline_header_count=1`, `draft_header_count=0`, per quick-doc flow/count bridges=1).
- Stage 8 reliability gate reminder: for each hardening delta run `bash shipinfo-agent-kit/scripts/release_gate.sh` and then run triage snapshot alias checks before handoff.
- Stage 8 hardening smoke bundle: `bash shipinfo-agent-kit/scripts/release_gate.sh && echo -n "triage_note_count="; grep -c "Baseline snapshot mismatch triage" shipinfo-agent-kit/docs/OPS_HANDOFF_RUNBOOK.md; echo -n "baseline_header_count="; grep -c '^Mirror baseline freeze marker (baseline):' AGENT_PLATFORM_SPRINTS.md; echo -n "draft_header_count="; grep -c '^Mirror baseline freeze marker (draft):' AGENT_PLATFORM_SPRINTS.md`.
- Stage 8 smoke bundle output contract: expected counters after smoke bundle are `triage_note_count=1`, `baseline_header_count=1`, `draft_header_count=0`.
- Stage 8 delta completion OPS mirror: after each hardening delta, re-run `Stage 8 quartet alias` checks and refresh the Stage-8 pre-handoff pass marker based on latest successful counters.
- Stage 8 cycle loop OPS mirror: run Stage-8 cycle in canonical order (readiness marker -> hardening delta -> quartet alias -> pass-marker refresh) before proceeding to the next delta.
- Stage 8 exit criteria OPS mirror: keep Stage-8 exit prerequisites stable (`gate+loop summary`, cycle loop marker, quartet alias, pre-handoff pass marker) before Stage-9 kickoff.
- Stage 9 governance kickoff marker: governance phase starts only after Stage-8 exit prerequisites are stable and documented in sprint tracker/changelog.
- Stage 9 governance checklist OPS mirror: run release gate, confirm quartet alias stability, and verify sprint/changelog audit updates before governance handoff.
- Stage 9 final close OPS mirror: run final close checklist consistency checks, verify close-statement/audit-pack/formal-close markers, then keep maintenance-only cadence.
- Stage 10 kickoff OPS mirror: start productization cycle only after Stage-9 formal close and next-stage intake consistency checks are stable.
- Stage 10 paid-flow OPS mirror: keep x402 paid-path checks, fair-value policy checks, and commission-ledger checks in daily maintenance chain.
- Stage 10 launch OPS mirror: before go/no-go, run runtime contract checks, UAT matrix checks, settlement reconciliation checks, and production handoff checklist.
- Stage 10 hypercare OPS mirror: after formal close marker, run daily hypercare triage for SLO, paid-flow health, disputes, and payout consistency.
- Stage 10 DR/chaos OPS mirror: run periodic chaos + DR rehearsals and verify incident/fallback/runbook parity.
- Stage 10 completion OPS mirror: keep post-close maintenance baseline cadence (daily/weekly/monthly) and verify next-program backlog consistency before new stage kickoff.
- Stage 11 kickoff OPS mirror: start ecosystem-scaling cycle only after Stage-10 completion and next-program backlog consistency are stable.
- Stage 11 revenue/risk OPS mirror: run revenue baseline checks, dynamic-commission guard checks, settlement-SLA checks, and fraud-risk checks in one operating chain.
- Stage 11 close OPS mirror: before stage close, verify pre-close checklist seed, close-statement seed, and close-readiness marker remain singular.
- Stage 12 kickoff OPS mirror: start enterprise/global-expansion cycle only after Stage-11 completion marker and post-close baseline are stable.
- Stage 12 enterprise controls OPS mirror: run tenant/SSO/residency/governance/security consistency checks as one enterprise control chain.
- Stage 12 close OPS mirror: before formal close, verify pre-close checklist, close statement, close readiness, and final close checklist markers remain singular.
- Stage 13 kickoff OPS mirror: start autonomous-economy cycle only after Stage-12 completion marker and post-close baseline are stable.
- Stage 13 autonomous economy OPS mirror: run network-effects, market-making, dynamic rail, coalition, and governance-guard checks in one operating chain.
- Stage 13 close OPS mirror: before formal close, verify pre-close checklist, close statement, close readiness, and final close checklist markers remain singular.
- Stage 14 kickoff OPS mirror: start open-financial-rail cycle only after Stage-13 completion marker and post-close baseline are stable.
- Stage 14 financial governance OPS mirror: run unified payment intent, settlement interface, fee router, escrow, treasury, and compliance-mesh checks in one operating chain.
- Stage 14 close OPS mirror: before formal close, verify pre-close checklist, close statement, close readiness, and final close checklist markers remain singular.

Maintenance backlog intake:
- Accept maintenance-only deltas (docs/ops hygiene) without contract-surface expansion.
- Keep payer-autonomy policy wording (`agent_self_assessed_fair_value`, `paid_interactions_only`) and maintenance guard-chain expectations unchanged unless a new roadmap stage is opened.
- Policy wording audit one-liner:
  - `grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md`
- Combined maintenance audit chain:
  - `grep -n "agent_self_assessed_fair_value\\|paid_interactions_only\\|paid interactions" shipinfo_analytics_api.md shipinfo_agent_native.md maritime_agent_coordination.md agent_native_api_quickstart.md shipinfo_api_discoverability_spec.md agent_hybrid_tier_upgrade.md shipinfo_mcp_sdk_release_spec.md && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/payer_autonomy_readiness.sh && bash scripts/agents/ops_health_status.sh && BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh`

Quick troubleshooting matrix:

| Symptom | Likely cause | Immediate action |
|---|---|---|
| `release_gate fail` in `agent_platform_handoff.log` | Regression in checks (links/contracts/smoke) | Re-run `bash shipinfo-agent-kit/scripts/release_gate.sh` and fix first failing stage |
| `contract_guard fail` with drift detected | API contract/OpenAPI changed vs baseline | Run regression checks, refresh baselines only for approved change, re-run gate |
| `mcp_contract_matrix` failure | MCP wrapper input/error contract changed | Re-run `bash shipinfo-agent-kit/scripts/mcp_contract_matrix.sh`, inspect wrapper/tool args validation |
| `registry_links` failure | Broken public endpoint/schema URL | Validate URL in registry, verify endpoint availability from `BASE_URL` |
| Manifest integrity check fail in CI summary | Artifact hash mismatch or stale manifest | Re-run `release_gate.sh` to regenerate report/checksums/manifest together |

Retention and rotation policy (recommended):

1. Keep `agent_platform_handoff.log` and `agent_contract_guard.log` for 14 days.
2. Keep `agent_platform_health_snapshot.json` as last-known state (single rolling file).
3. Rotate large logs with `logrotate` daily and `compress`.
4. Before deleting old logs, ensure latest handoff status is `ok` in snapshot JSON.
