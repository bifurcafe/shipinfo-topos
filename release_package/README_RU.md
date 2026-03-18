# ShipInfo Agent Kit: Готовый пакет публикации

Этот пакет нужен, чтобы быстро и безопасно завершить внешний релиз:
- MCP registry entry
- GitHub репозиторий
- npm пакет
- PyPI пакет

## 1) Что уже подготовлено

- Registry entry: `shipinfo-agent-kit/registry/shipinfo-analytics.json`
- MCP server: `shipinfo-agent-kit/packages/mcp-server`
- JS SDK (npm): `shipinfo-agent-kit/packages/sdk-js`
- Python SDK (PyPI): `shipinfo-agent-kit/packages/sdk-py`
- Publish docs:
  - `shipinfo-agent-kit/docs/MCP_REGISTRY_PUBLISH.md`
  - `shipinfo-agent-kit/docs/NPM_PUBLISH.md`
  - `shipinfo-agent-kit/docs/PYPI_PUBLISH.md`
- Release gate:
  - `bash shipinfo-agent-kit/scripts/release_gate.sh`

## 2) Входные данные перед публикацией

1. Скопируйте:
`cp shipinfo-agent-kit/release_package/PUBLISH_INPUTS.template.env shipinfo-agent-kit/release_package/PUBLISH_INPUTS.env`
2. Заполните `PUBLISH_INPUTS.env`:
- GitHub org/repo/visibility
- npm package name/scope
- PyPI package name/mode
- MCP registry mode/repo URL
- Токены:
  - `GITHUB_TOKEN` (repo create/push + PR)
  - `NPM_TOKEN`
  - `PYPI_API_TOKEN`
  - `MCP_REGISTRY_GITHUB_TOKEN`

3. Проверка готовности входов (авто):
`bash shipinfo-agent-kit/scripts/publish_preflight_inputs.sh shipinfo-agent-kit/release_package/PUBLISH_INPUTS.env`

Ожидаемо:
- `publish_preflight_status=ready` — можно запускать внешний publish-проход.
- `publish_preflight_status=blocked` — в выводе будут `missing: ...` для незаполненных полей.

## 4) Предрелизная проверка (обязательно)

```bash
cd /var/www/shipinfo.net/topos
bash shipinfo-agent-kit/scripts/release_gate.sh
```

Ожидаемый итог: `release_gate: pass`

## 5) Сборка релизного пакета-артефакта

```bash
cd /var/www/shipinfo.net/topos
bash shipinfo-agent-kit/scripts/build_release_package.sh
```

На выходе:
- `shipinfo-agent-kit/release_package/dist/shipinfo_agent_kit_publish_YYYYmmdd_HHMMSS_UTC.tar.gz`

Содержимое архива:
- `registry/shipinfo-analytics.json`
- `schemas/*.json`
- `packages/mcp-server/*`
- `packages/sdk-js/*`
- `packages/sdk-py/*`
- `docs/MCP_REGISTRY_PUBLISH.md`
- `docs/NPM_PUBLISH.md`
- `docs/PYPI_PUBLISH.md`
- `docs/RELEASE_CHECKLIST.md`
- `reports/release_report_latest.json`
- `reports/checksums_sha256.txt`
- `reports/release_manifest.json`

## 6) Порядок внешней публикации

1. GitHub: push/PR репозитория `shipinfo-agent-kit`.
2. npm: публикация JS SDK по инструкции `docs/NPM_PUBLISH.md`.
3. PyPI: публикация Python SDK по инструкции `docs/PYPI_PUBLISH.md`.
4. MCP Registry: PR или публикация в ваш registry по `docs/MCP_REGISTRY_PUBLISH.md`.
5. После merge/update:
   - проверить ссылки `/topos/api/.well-known/*`
   - проверить `registry/shipinfo-analytics.json` версия/URL актуальны.

## 7) Что НЕ делать

- Не публиковать токены в репозитории.
- Не коммитить `.env` с секретами.
- Не публиковать wallet metadata без явного решения.
