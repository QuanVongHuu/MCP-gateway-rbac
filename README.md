# MCP-gateway-rbac

## Problem

A finance company's data department runs four teams on a shared data/ML stack (Spark, Airflow, HDFS + ClickHouse, OpenMetadata). Both humans and AI agents from these teams need to call into that stack through **one shared MCP endpoint** — but not all of them should be allowed to do the same things through it.

Concretely:

- **Quản trị rủi ro** (Risk management)
- **Quản trị dữ liệu** (Data governance)
- **Phát triển dự án** (Project development)
- **Dịch vụ khách hàng — thu hồi nợ** (Customer service / debt collection)

Each team — and increasingly, each AI agent acting on a team's behalf — should see and be able to call only the tools appropriate to its role. Right now there's no such boundary: anything reaching the endpoint has the same access as anything else.

**Goal:** stand up an MCP gateway that authorizes every caller (human or agent) by role, so the same endpoint returns a different, correctly-scoped set of tools depending on who's asking.

This is an internship deliverable, not a class exercise — built for a real internal system.

## Role → tool mapping (draft, TBD)

Placeholder — fill in once each team's actual tool needs are confirmed.

| Team | Spark | Airflow | HDFS + ClickHouse | OpenMetadata |
|---|---|---|---|---|
| Quản trị rủi ro | ? | ? | ? | ? |
| Quản trị dữ liệu | ? | ? | ? | ? |
| Phát triển dự án | ? | ? | ? | ? |
| Dịch vụ khách hàng (thu hồi nợ) | ? | ? | ? | ? |

## Current plan

Based on the research in [local-docs/](local-docs/):

- **Gateway:** [IBM ContextForge](https://github.com/IBM/mcp-context-forge) (vendored in [mcp-context-forge/](mcp-context-forge/)) — chosen over agentgateway, Azure API Management, and Microsoft's `mcp-gateway` because it ships the two pieces this problem actually needs out of the box: **virtual servers** (a curated tool subset composed from multiple backend MCP servers) and a **two-layer RBAC model** (token/team scoping on `tools/list` discovery, plus per-route `@require_permission` checks on `tools/call` invocation). Filtering discovery alone isn't enough — invocation has to be independently authorized too, or a model can still call a tool it was never shown.
- **Identity:** Microsoft Entra ID as the OAuth 2.1 authorization server, mapping Entra groups/app roles → ContextForge teams/roles.
- **Deployment:** Azure AKS, via ContextForge's official Helm chart (`charts/mcp-stack`).

None of this is implemented yet — see Status below.

## Status

**Research/planning stage.** No RBAC code written on top of the vendored gateway yet.

**Next milestone:** a PoC inside ContextForge — register the backend servers as gateways, create two virtual servers scoped to two different teams (tool sets TBD per the mapping above), and verify with [MCP Inspector](https://github.com/modelcontextprotocol/inspector) that `tools/list` returns only the permitted tools per team, and that calling a disallowed tool is actually rejected (not just hidden).

## Repo layout

- [mcp-context-forge/](mcp-context-forge/) — vendored upstream gateway (IBM ContextForge), unmodified so far.
- [local-docs/](local-docs/) — working research and notes:
  - [deep-research-MCPGateWay.md](local-docs/deep-research-MCPGateWay.md) — gateway options compared (ContextForge vs agentgateway vs APIM vs others), MCP auth spec background, Azure/AKS deployment notes.
  - [mcp-gateway_personal-doc.md](local-docs/mcp-gateway_personal-doc.md) — ContextForge's architecture and RBAC internals, read directly from the vendored source (middleware stack, `db.py` entities, `middleware/rbac.py` permission check flow).
  - [mcp-gateway-guideline.md](local-docs/mcp-gateway-guideline.md) — how to mock a backend MCP server and an agent client (MCP Inspector) for local testing, since there's no real agent platform to test against yet.

## Why this README exists

Written to double as a working-memory doc — for picking this project back up cold later, and as context for AI assistants helping on it. If you're an AI reading this to help with the next step: the immediate task is the PoC in "Status" above, using ContextForge's virtual-server + RBAC features already described in [mcp-gateway_personal-doc.md](local-docs/mcp-gateway_personal-doc.md) §3 and §6.
