# Policy-overlap experiment

**Question:** how does agentgateway combine several MCP authorization policies? The answer decides how `rbac/tool-access.yaml` is structured.

**Setup (8/10/2026):** kind cluster, agentgateway v1.5.0, backend `mcp-backend` (namespace `mcp`, `prefixMode: Always`) with the five mock targets (21 tools), JWT policy `deploy/auth/jwt.yaml` on the Gateway, Keycloak realm `mcp`. Each user logs in through `mcp-cli`, opens a new MCP session and calls `tools/list`. Every policy was a throwaway and is deleted.

| User | Roles in the token |
|---|---|
| `analyst.user` | `analyst` |
| `engineer.user` | `data_engineer` |
| `multi.user` | `data_engineer`, `bi_engineer` |
| `admin.user` | `data_admin` |
| `nobody.user` | none |

Shorthand: **OM-read** = `openmetadata_search_metadata`, `openmetadata_get_entity_details`, `openmetadata_get_entity_lineage`. **radar×4** = all four radar tools. **radar×3** = radar without `manage_workload`. **all** = all 21 tools.

## 0. Baseline and naming

| Policy on the backend | Result |
|---|---|
| None | Every user, `nobody.user` included, sees **all** 21 tools |
| Allow `mcp.tool.name == "list_namespaces"` | `radar_list_namespaces` only |
| Allow `mcp.tool.name == "radar_list_namespaces"` | nothing |
| Allow `mcp.tool.target == "radar"` | radar×4 |

- `mcp.tool.name` is the **unprefixed** tool name. The target is matched separately with `mcp.tool.target`.
- With no authorization policy the backend is open to any valid token.

## 1. Two Allow policies (both on the backend)

- Policy A: `analyst` or `bi_engineer` → OM-read
- Policy B: `data_engineer` → target `radar`

| User | A + B | A only (control) |
|---|---|---|
| `analyst.user` | OM-read | OM-read |
| `engineer.user` | radar×4 | none |
| `multi.user` | OM-read + radar×4 | OM-read |
| `admin.user` | none | none |
| `nobody.user` | none | none |

**Finding:** Allow policies are OR-ed. A tool is visible if any Allow policy matches. Once one Allow policy exists, anything unmatched is denied.

## 2. Allow + Deny (both on the backend)

- Allow: `data_engineer` → target `radar`; `data_admin` → everything
- Deny: radar `manage_workload` for everyone; `bi_engineer` → target `radar`

| User | Allow + Deny | Deny only (control) |
|---|---|---|
| `analyst.user` | none | all minus `radar_manage_workload` (20) |
| `engineer.user` | radar×3 | all minus `radar_manage_workload` (20) |
| `multi.user` | none | all minus radar (17) |
| `admin.user` | all minus `radar_manage_workload` (20) | all minus `radar_manage_workload` (20) |
| `nobody.user` | none | all minus `radar_manage_workload` (20) |

**Findings:**
- Deny wins over Allow, even over the `data_admin` "everything" rule.
- Deny is evaluated per user, not per role: `multi.user` loses radar because of `bi_engineer`, although `data_engineer` allows it.
- A Deny policy alone does not close the backend. Without an Allow policy everything not denied stays open.

## 3. Gateway-level policy + Backend-level policy

The Gateway-level policy uses the same `backend.mcp.authorization` block, with `targetRefs` pointing at Gateway `agentgateway-proxy`.

| User | 3a: Gateway Allow only (`data_engineer` → radar) | 3b: 3a + Backend Allow (`analyst` or `bi_engineer` → OM-read) | 3c: Gateway Deny (radar `manage_workload`) + Backend Allow (`data_engineer` → radar, `data_admin` → all) |
|---|---|---|---|
| `analyst.user` | none | OM-read | none |
| `engineer.user` | radar×4 | radar×4 | radar×3 |
| `multi.user` | radar×4 | OM-read + radar×4 | radar×3 |
| `admin.user` | none | none | all minus `radar_manage_workload` (20) |
| `nobody.user` | none | none | none |

**Findings:**
- The two levels are merged, not overridden. Allow rules from both levels are OR-ed (3b), and a Gateway-level Deny still beats a Backend-level Allow (3c).
- A Backend-level policy therefore cannot narrow what a Gateway-level Allow grants.

**`tools/call` check (3c, `engineer.user`):** `radar_manage_workload` → HTTP 400, `Unknown tool: radar_manage_workload`. `radar_list_namespaces` → 200 with the result. The filter applies to calls, not only to the list.

## What this means for `rbac/tool-access.yaml`

- The default holds: **one Allow policy on `mcp-backend`**, every expression guarded by `has(jwt.roles)` and checking a role. Splitting it into several Allow policies gives the same result (union), so one file is simpler to review.
- Write rules as `mcp.tool.target == "<target>" && mcp.tool.name in ["<unprefixed tool>", …]`.
- The Allow policy must always exist: without it the backend is open to any valid token.
- Use Deny only for a hard block that no role may get past, `data_admin` included. Do not use it for per-role limits: a user with several roles loses the tool if any one of their roles is denied.
- Keep tool rules off the Gateway. A Gateway-level Allow widens access for every backend behind it and a Backend-level policy cannot take it back.
