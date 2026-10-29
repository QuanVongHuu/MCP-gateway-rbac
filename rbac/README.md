# rbac

**What:** the policy: which role may call which MCP tool. It is the source of truth for authorization, kept apart from infrastructure because it changes often and needs its own review.

**Contains:**
- `tool-access.yaml`: deny-by-default `AgentgatewayPolicy` with `Allow` expressions for the ten AI Agent capability roles.

**Rules of the format:**
- every rule checks a role, guarded by `has(jwt.roles)`
- rules are OR-ed, so several roles give the union
- no matching rule means no access
- pair `mcp.tool.name` with `mcp.tool.target`

**README mapping:** *Authorization* checkpoint; *Common changes* ("give a role access to more tools"). Build step 4, guideline §4.

**When you change it:** update `tests/expected/agent-tool-access.json` in the same pull request and run `node tests/static_contract_test.mjs` plus the live RBAC smoke test.
