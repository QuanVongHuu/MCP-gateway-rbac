# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Quick reference

- Python tests need `mcp==1.30.0`. There are no unit tests; each script is end-to-end. Run one test by running its script.
- `servers/smoke_test.py` runs locally. `tests/gateway_smoke.py` needs the gateway port-forwarded to `localhost:8080`. `tests/agent_rbac_smoke.py` also needs Keycloak and per-agent secrets.
- `node tests/static_contract_test.mjs` checks the manifests and contracts without a cluster. Run it after you edit any YAML under `deploy/`, `rbac/` or `servers/k8s/`.
- If you add, remove or rename a tool, update all of these in one change: `servers/<target>/server.py`, `AgentgatewayBackend.yaml`, `rbac/tool-access.yaml`, `tests/expected/agent-tool-access.json`, the `CASES` mapping in `tests/gateway_smoke.py`, and the 21-tool count.
