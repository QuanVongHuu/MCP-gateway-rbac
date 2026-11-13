# MCP Gateway RBAC — Agent Guide

## Purpose and architecture

This repository is a configuration-first proof of concept for exposing several MCP servers through a single `agentgateway` endpoint (`/mcp`) on a local kind cluster. The intended trust chain is:

`MCP client -> agentgateway -> multiplexed MCP backends`

Keycloak-issued JWTs should authenticate callers; gateway policies should authorize individual tools by role; verified caller identity is forwarded to backends; NetworkPolicy makes the gateway the only backend ingress path. Do not add custom gateway application code unless the task explicitly requires it.

## What exists today

- `deploy/agentgateway/` routes `/mcp` to one `AgentgatewayBackend` in namespace `mcp`. It multiplexes five Streamable HTTP targets and uses `prefixMode: Always`, producing names such as `radar_list_namespaces`.
- `servers/` contains Python/FastMCP canned-data mocks for `radar`, `spark-history`, `openmetadata`, `dbt`, and `airflow`. `servers/k8s/mocks.yaml` deploys all five from one image (`mcp-mocks:dev`).
- `tests/gateway_smoke.py` asserts the federated catalog has 21 tools and calls each one through `http://127.0.0.1:8080/mcp`. The successful captured output is in `evidence/gateway-smoke.txt`.
- `deploy/keycloak/`, `deploy/auth/`, `rbac/`, `deploy/network/` and `observability/access-logs/` contain live-validated AI Agent identity, JWT, tool authorization, network and audit manifests. Results are captured in `evidence/agent-rbac-smoke.txt`.
- `tests/expected/agent-tool-access.json` is the machine-readable Agent x Role x Tool contract; `tests/agent_rbac_smoke.py` verifies token claims, visible tools, allowed calls and denied calls.
- `servers/smoke_test.py` runs the five mocks locally and verifies that mocks can observe forwarded identity headers and an authorization token.
- `demo-agentgateway-setup/` is an independent tutorial/example for a Kubernetes MCP server. It is not the main deployment path.

## Planned/incomplete areas — verify before relying on them

The AI Agent security MVP is validated with agentgateway v1.5.0 and Keycloak 26.2.5. OpenMetadata token exchange, real-backend resource authorization and delegated human identity remain incomplete. `local-docs/mcp-gateway-guideline.md` is an older starting point; fields marked `check` must not override the tested contract.

The root README and guideline have some stale descriptions (they say three backends or that dbt/Airflow are planned), while the active backend and mock manifests contain five targets. Treat `deploy/agentgateway/AgentgatewayBackend.yaml`, `servers/k8s/mocks.yaml`, and `tests/gateway_smoke.py` as the current source for the deployed tool catalog.

## Layout and ownership

- `deploy/agentgateway/`: active Gateway API and agentgateway manifests.
- `servers/<target>/server.py`: mock MCP tool definitions; shared server creation and safe identity logging live in `servers/mockkit.py`.
- `servers/k8s/mocks.yaml`: all mock Deployments and Services. Keep its target names aligned with `deploy/agentgateway/AgentgatewayBackend.yaml`.
- `tests/gateway_smoke.py`: end-to-end catalog/call smoke test. Update its `CASES` mapping whenever a tool is added, removed, or renamed.
- `local-docs/mcp-gateway-guideline.md`: intended build/security design and commands, not authoritative runnable configuration.
- `rbac/tool-access.yaml`: source of truth for role-to-tool policy. Update `tests/expected/agent-tool-access.json` in the same change.

## Conventions and safety invariants

- Clients must use the gateway `/mcp` endpoint, never reach an MCP backend directly.
- Keep a backend target name identical across its mock directory, Service, `AgentgatewayBackend` target, RBAC rules, and tests. Client-visible tools are `{target}_{tool}`.
- Tool authorization is deny-by-default. Role rules are intended to be OR-ed; a multi-role user receives the union.
- Never forward a caller's original token to ordinary backends. Header identity must be set/replaced only after JWT validation, and depends on enforced backend-only NetworkPolicy. OpenMetadata is intended to use an exchanged, audience-scoped token.
- Do not commit client secrets, access tokens, decoded sensitive claims, or evidence containing them. The mock logger intentionally records only selected non-secret token claims.

## Useful verification commands

Run Python tests with an environment containing `mcp==1.30.0` (the mock Docker image pins that version):

```bash
python servers/smoke_test.py
python tests/gateway_smoke.py  # requires a reachable gateway at localhost:8080
python tests/agent_rbac_smoke.py  # also requires Keycloak and per-agent secrets
node tests/static_contract_test.mjs
```

For a cluster deployment, build/load the common mock image, apply `servers/k8s/mocks.yaml` and the three manifests under `deploy/agentgateway/`, then port-forward the proxy to `8080`. The exact agentgateway, Gateway API, Keycloak, JWT, RBAC, token-exchange, network-policy, and audit-log steps remain subject to the validation notes in `local-docs/mcp-gateway-guideline.md`.

## Tool inventory

The current smoke contract is 21 tools: radar (4), spark-history (3), openmetadata (4), dbt (5), and airflow (5). Some mock tools are explicitly write-shaped but have no side effects; preserve that property unless a task calls for integration with a real service.
