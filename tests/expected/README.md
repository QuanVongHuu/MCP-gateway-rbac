# tests/expected

**What:** the expected behaviour as data: the role × tool allow/deny matrix for the five test users, plus the expected `tools/list` per user.

**Contains:**
- `agent-tool-access.json`: canonical 21-tool catalog and Agent → roles → visible tools matrix, including a no-access negative-test agent.

**README mapping:** *Test users* table; *Common changes* (changing `rbac/` means changing this in the same PR).

**How it's used:** `tests/inspector/` and `tests/curl/` produce actual results; a script compares them with this file. Keeping the data separate means a policy change edits one file, not the test scripts.

**Validation:** `tests/static_contract_test.mjs` checks this file against the gateway smoke catalog, Keycloak clients/roles and RBAC policy. `tests/agent_rbac_smoke.py` validates it against a running deployment.
