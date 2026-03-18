# Cron Contract Guard

Script:
- `scripts/agents/cron_agent_contract_guard.sh`

Purpose:
- Detect drift in API capability/schemas snapshots and OpenAPI paths.
- Optional auto-refresh mode.

Manual run:
```bash
BASE_URL=https://shipinfo.net/topos/api bash scripts/agents/cron_agent_contract_guard.sh
```

Auto-refresh run:
```bash
BASE_URL=https://shipinfo.net/topos/api AUTO_REFRESH_ON_DRIFT=1 bash scripts/agents/cron_agent_contract_guard.sh
```

Example cron (every 30 minutes):
```cron
*/30 * * * * BASE_URL=https://shipinfo.net/topos/api /bin/bash /var/www/shipinfo.net/topos/scripts/agents/cron_agent_contract_guard.sh >> /var/www/shipinfo.net/topos/logs/agent_contract_guard.cron.log 2>&1
```

Approved baseline refresh checklist:

1. Confirm contract/path change is intentional and reviewed.
2. Run drift checks and capture failing diff context:
   - `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/check_contract_regression.sh`
   - `BASE_URL=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/check_openapi_regression.sh`
3. Refresh baselines explicitly:
   - `BASE_URL=https://shipinfo.net/topos/api OUT_DIR=shipinfo-agent-kit/contracts/baseline bash shipinfo-agent-kit/scripts/capture_contract_snapshot.sh`
   - `BASE_URL=https://shipinfo.net/topos/api OUT_DIR=shipinfo-agent-kit/contracts/baseline bash shipinfo-agent-kit/scripts/capture_openapi_snapshot.sh`
4. Re-run full gate:
   - `BASE_URL=https://shipinfo.net/topos/api SHIPINFO_API_BASE=https://shipinfo.net/topos/api bash shipinfo-agent-kit/scripts/release_gate.sh`
5. Update `CHANGELOG_AGENT.md` with reason, scope, and verification evidence.
