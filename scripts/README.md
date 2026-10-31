# scripts

**What:** the things you do repeatedly, so long one-liners are not copied around.

**Contains:**
- `get-token.sh <user>`: fetch an access token from Keycloak, e.g. `TOKEN=$(scripts/get-token.sh engineer.user)`.
- `up.sh`: apply the `deploy/` layers in order (the build order lives here as executable code). Safe to re-run. It expects guideline §1 done and does not start the real servers (`deploy/real-servers/`).
- `run-tests.sh`: run `tests/curl/` and `tests/inspector/` and compare with `tests/expected/`. Exit code 0 only if all pass; takes about two minutes.

**Needs:** `kubectl`, `curl`, `jq`, Node 22.19+, and for the tests the two port-forwards (gateway on 8080, Keycloak on 8002).
- `bootstrap-agent-secrets.sh`: generate Keycloak bootstrap and per-agent client secrets directly into Kubernetes Secrets without printing their values. It is idempotent and refuses partial rotation.
- `up.sh`: apply Keycloak, mocks, gateway, authentication, tool RBAC, Kubernetes RBAC, NetworkPolicy and audit policy in dependency order. agentgateway CRDs and the `mcp-mocks:dev` image must already exist.
- `run-agent-rbac-tests.sh`: load agent secrets from Kubernetes and run `tests/agent_rbac_smoke.py` without printing tokens.

**README mapping:** *How to leverage it* (the build order). Guideline §3 (token) and §8 (tests).

**Rule:** scripts orchestrate. Config belongs in `deploy/` and `rbac/`, not here. Secret values must never be committed or echoed.
