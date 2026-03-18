# Release Manifest

Generate release manifest after report + checksums:

```bash
bash shipinfo-agent-kit/scripts/release_report.sh
bash shipinfo-agent-kit/scripts/generate_checksums.sh
bash shipinfo-agent-kit/scripts/generate_release_manifest.sh
```

Output:
- `shipinfo-agent-kit/reports/release_manifest.json`

CI integrity verification:
- `verify-agent-kit` workflow step `Publish verification summary` validates manifest hashes for:
  - `release_report`
  - `checksums_manifest`
  - `registry_entry`
- On mismatch or missing artifact, the summary step fails the workflow.
