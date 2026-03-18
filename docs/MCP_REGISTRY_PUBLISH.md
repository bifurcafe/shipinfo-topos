# MCP Registry Publish Guide

1. Validate `registry/shipinfo-analytics.json` fields and URLs.
   - Include x402 discoverability URLs (`x402_requirements_url`, `x402_verify_url`) when enabled.
   - Ensure `.well-known/openapi.json` includes x402 paths (`/v1/billing/x402/requirements`, `/v1/billing/x402/verify`).
2. Verify tools map to existing API paths and schema URLs.
3. Run local smoke checks for well-known + v1 endpoints.
4. Prepare PR to selected MCP registry repository.
5. After merge, reference registry entry from integration docs.
