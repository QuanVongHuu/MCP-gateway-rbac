# tests/expected

**What:** the expected behaviour as data: the role × tool allow/deny matrix for the five test users, plus the expected `tools/list` per user.

**Contains:**
- `tools.json`: user → the exact tools that user's `tools/list` must return, sorted. It reflects the backends currently behind the gateway (real radar, OpenMetadata and Spark History Server MCP; mock dbt and airflow), so it also changes when a mock is swapped for a real server or back.
- `calls.json`: a list of `{user, tool, args, expect}` with `expect` being `allow` or `deny`. Keep the `allow` cases read-only: they really run. A `deny` case never reaches a backend, so it can name a write tool.

**Regenerate `tools.json` after an intended change** (review the diff before committing):

```bash
for u in analyst engineer multi admin nobody; do
  npx -y @modelcontextprotocol/inspector@0.21.2 --cli http://localhost:8080/mcp --transport http \
    --header "Authorization: Bearer $(scripts/get-token.sh $u.user)" --method tools/list \
    | jq -c --arg u "$u.user" '{($u): ([.tools[].name] | sort)}'
done | jq -s add > tests/expected/tools.json
```
- `agent-tool-access.json`: canonical 21-tool catalog and Agent → roles → visible tools matrix, including a no-access negative-test agent.

**README mapping:** *Test users* table; *Common changes* (changing `rbac/` means changing this in the same PR).

**How it's used:** `tests/inspector/` and `tests/curl/` produce actual results; a script compares them with this file. Keeping the data separate means a policy change edits one file, not the test scripts.

**Validation:** `tests/static_contract_test.mjs` checks this file against the gateway smoke catalog, Keycloak clients/roles and RBAC policy. `tests/agent_rbac_smoke.py` validates it against a running deployment.
