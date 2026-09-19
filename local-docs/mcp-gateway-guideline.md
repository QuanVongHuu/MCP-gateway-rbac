# MCP Gateway — Mock Server / Mock Agent Guideline

You don't need to go hunting for external tutorials for most of this. Your own `mcp-context-forge/` checkout already has everything needed to build a full mock setup, plus the official MCP protocol docs for the parts it doesn't cover.

## 1. Mock backend MCP servers — already in your repo, no building needed

`mcp-context-forge/mcp-servers/python/` ships ready-to-run sample servers you can register with the gateway right now:

- `data_analysis_server`, `graphviz_server`, `mcp_eval_server`, `mcp-rss-search`, `output_schema_test_server`, `url_to_markdown_server`

Note: the Go `fast-time-server`, `qr_code_server`, and the Rust servers (`slow-time-server`, `benchmark-server`, `filesystem-server`) mentioned in upstream docs are **not** in this checkout. Use one of the Python samples above, or scaffold your own (§2).

## 2. Want your own mock server instead of the samples?

There's scaffolding for that too:

```bash
./mcp-servers/scaffold-python-server.sh my-server
./mcp-servers/scaffold-go-server.sh my-server
```

Backed by cookiecutter templates in `mcp-servers/templates/`. One command gives you a minimal working MCP server skeleton (`tools/list` + `tools/call` wired up) you can then customize — e.g. to add a tool that only makes sense under an "admin" role, so you can actually exercise your RBAC layer.

## 3. The "no real agent platform" problem — MCP Inspector

This is the actual answer to the core blocker. `npx @modelcontextprotocol/inspector` is the official reference *client* — it's a mock agent platform. It has three modes:

- Web GUI (default): `npx @modelcontextprotocol/inspector`
- Scriptable CLI (good for automated tests): `npx @modelcontextprotocol/inspector --cli ...`
- TUI: `npx @modelcontextprotocol/inspector --tui ...`

Point it at your gateway's HTTP endpoint:

```bash
npx @modelcontextprotocol/inspector --server-url https://your-gateway/mcp --transport http
```

Or at a local stdio server directly:

```bash
npx @modelcontextprotocol/inspector node path/to/server/index.js
```

It lets you browse tools, call them, and inspect raw JSON-RPC traffic — no Claude Desktop or real agent needed. This is the standard way to develop/test MCP servers and gateways without a live agent.

CLI example (scriptable, pipeable):

```bash
npx @modelcontextprotocol/inspector --cli node path/to/server/index.js --method tools/list

npx @modelcontextprotocol/inspector --cli https://api.example.com/mcp --transport http \
  --method tools/call --tool-name get_weather --tool-arg city=Boston --format json | jq .result
```

Requires Node 22.19.0+.

## 4. If you want to understand the protocol from first principles

Rather than through the gateway's abstraction, the official quickstart at [modelcontextprotocol.io/quickstart/server](https://modelcontextprotocol.io/quickstart/server) walks through building a minimal weather server (Python/TS/etc.), covering the three primitives (tools / resources / prompts) and the stdio transport basics. It builds two tools, `get_alerts` and `get_forecast`, and connects them to an MCP host.

Inspector docs: [modelcontextprotocol.io/docs/tools/inspector](https://modelcontextprotocol.io/docs/tools/inspector)

## Open question — two different next steps

Given this project is specifically building RBAC on top of a gateway, there are two different directions:

- **(a) End-to-end smoke test** — gateway + a sample backend + Inspector, just to see the plumbing work.
- **(b) Deliberately role-differentiated mock server** — e.g. tools tagged for different permission scopes, so you can actually exercise and demo the RBAC logic itself.

These lead to pretty different next steps — worth deciding which one is the immediate goal before scaffolding anything.

## Project folder structure

`mcp-context-forge/` is upstream code and is never edited. All our own work lives in sibling folders, one per phase of the task plan below. Each folder has its own `README.md` explaining what goes in it.

```
MCP-gateway-rbac/
├── mcp-context-forge/        # upstream IBM ContextForge — don't edit (gitignored)
├── servers/                  # Quân · Tasks 1–2 — mock backend MCP servers
│   ├── risk-tools/
│   ├── debt-collection-tools/
│   └── admin-tools/          # admin-only tool that RBAC must block
├── gateway/                  # Quân · Tasks 3, 5, 6 — deployment + setup
│   ├── .env.example          # copy to .env (gitignored)
│   └── register/             # numbered admin-API scripts: backends → teams → virtual servers
├── rbac/                     # Quân · Tasks 4, 7, 15 — role model
│   ├── role-tool-mapping.md  # team → tool table (human-readable)
│   ├── roles.yaml            # same mapping as data, read by gateway/register/
│   └── patches/              # changes to upstream code (e.g. rbac.py) as .patch files
├── observability/            # Huy · Tasks 8–11, 16 — audit log, tracing, metrics
│   ├── notes.md              # Task 8 architecture review
│   ├── otel/
│   ├── prometheus/
│   └── dashboards/           # allow/deny view per team
├── tests/                    # Quân & Huy · Tasks 12, 13, 17 — Inspector verification
│   ├── inspector/            # --cli scripts, pointed at the gateway, not the raw backend
│   └── expected/             # expected tools/list output per team, for diffing
├── evidence/                 # Task 14 — raw material for the report
│   ├── screenshots/
│   ├── logs/
│   └── configs/
└── local-docs/               # research notes (this file)
```

Rules:

- **Never edit inside `mcp-context-forge/`.** If Task 7 needs a code change, save it in `rbac/patches/`. This keeps upstream upgrades easy and separates our contribution from IBM's in the report.
- **Setup is scripted, not clicked.** `gateway/register/` + `rbac/roles.yaml` should rebuild the whole setup, so Task 17's dry run is one command and Task 15 fixes show up as diffs.
- **Blocked, not just hidden.** `tests/` scripts compare actual `tools/list` / `tools/call` results against `tests/expected/` — that's the evidence for Task 13.

## Detailed Task Plan

Two-person split: **Quân** builds the RBAC layer (backend → gateway registration → virtual servers → permission checks). **Huy** builds the monitoring/observability layer (ContextForge's audit logging + OpenTelemetry/Prometheus, per [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md)) and cross-verifies RBAC decisions actually get logged. Both converge for Inspector-based verification and final writeup.

Dates are bounded by **D3** in `Kien-tap-Deadlines.md` — the "Kiến tập tại DN & Phần 02 của đồ án" window, **04/9/2026 → 04/11/2026**. Planning starts 18/9/2026 (today is 17/9/2026, so nothing is scheduled retroactively into the already-elapsed 04/9–17/9 stretch). Row 14 lands on 15/10/2026 to feed the D3 milestone "Xong bản nháp báo cáo ≥35 trang, gửi GVHD duyệt." Row 18 closes on 04/11/2026, D3's hard boundary — nothing here should slip past it.

| NO | TASK TITLE | DETAIL TASK | START DATE | DUE DATE | TASK OWNER | Reference/ LINK | PROCESS | NOTE |
|---|---|---|---|---|---|---|---|---|
| 1 | Stand up mock backend server | Pick a sample from `mcp-servers/python/` (e.g. `data_analysis_server`) or scaffold one into `servers/`, and run it locally as the first backend MCP server | 18/9/2026 | 21/9/2026 | Quân | [mcp-gateway-guideline.md §1](mcp-gateway-guideline.md); `mcp-context-forge/mcp-servers/` | Not Started | Foundation for everything downstream |
| 2 | Add role-differentiated tool | Scaffold a second mock server (or extend the first) with an "admin-only" tool so RBAC has something real to gate | 22/9/2026 | 23/9/2026 | Quân | [mcp-gateway-guideline.md §2](mcp-gateway-guideline.md); `mcp-servers/scaffold-python-server.sh` | Not Started | Depends on Task 1; needed to demo option (b), not just plumbing |
| 3 | Register backend as a Gateway | Point ContextForge at the mock server(s) so they become gateway sources | 24/9/2026 | 25/9/2026 | Quân | [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md); https://github.com/IBM/mcp-context-forge | Not Started | Depends on Tasks 1–2 |
| 4 | Define team/role mapping | Draft the 4-team → tool-scope mapping from the README table (Risk, Data governance, Project dev, Debt collection) against the tools actually available | 24/9/2026 | 26/9/2026 | Quân | [README.md](../README.md) Role → tool mapping table; [mcp-gateway_personal-doc.md §3](mcp-gateway_personal-doc.md) | Not Started | Fills the README's TBD mapping table |
| 5 | Configure virtual server A | Compose a virtual server scoped to Team 1's tool subset | 29/9/2026 | 1/10/2026 | Quân | [mcp-gateway_personal-doc.md §3](mcp-gateway_personal-doc.md) | Not Started | Depends on Task 4 |
| 6 | Configure virtual server B | Compose a second virtual server scoped to Team 2's (different) tool subset | 2/10/2026 | 3/10/2026 | Quân | [mcp-gateway_personal-doc.md §3](mcp-gateway_personal-doc.md) | Not Started | Needs to differ meaningfully from Task 5 for the demo to mean anything |
| 7 | Wire per-route permission checks | Add `@require_permission` checks on `tools/call` so invocation is independently authorized, not just discovery | 5/10/2026 | 7/10/2026 | Quân | [mcp-gateway_personal-doc.md §6](mcp-gateway_personal-doc.md) `middleware/rbac.py` | Not Started | This is the part that stops a model calling a tool it was never shown |
| 8 | Review observability architecture | Read up on ContextForge's `PermissionAuditLog`, `ObservabilityMiddleware`, and OpenTelemetry hooks before configuring anything | 18/9/2026 | 22/9/2026 | Huy | [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md) (Observability, `PermissionAuditLog`) | Not Started | Runs in parallel with Task 1 |
| 9 | Enable audit logging | Turn on logging of grant/deny decisions on every `tools/call` (who, which tool, when) | 24/9/2026 | 26/9/2026 | Huy | [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md) `PermissionAuditLog`; [deep-research-MCPGateWay.md](deep-research-MCPGateWay.md) (Stage 4 audit logging) | Not Started | Depends on Task 8 |
| 10 | Configure OpenTelemetry export | Wire up a local exporter (console or Jaeger/Prometheus) for request tracing/metrics | 29/9/2026 | 1/10/2026 | Huy | [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md) `ObservabilityMiddleware`, `OpenTelemetryRequestMiddleware` | Not Started | Depends on Task 8 |
| 11 | Build allow/deny view | Assemble a simple log or dashboard view showing allow vs. deny events per team, for the demo | 2/10/2026 | 5/10/2026 | Huy | [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md) (Prometheus/Jaeger/Phoenix) | Not Started | Depends on Task 9–10 |
| 12 | Inspector: verify `tools/list` scoping | Point MCP Inspector at the gateway endpoint (not the raw backend) and confirm each team sees only its own tools | 8/10/2026 | 9/10/2026 | Quân & Huy | [mcp-gateway-guideline.md §3](mcp-gateway-guideline.md); https://github.com/modelcontextprotocol/inspector | Not Started | Depends on Tasks 5–7; first joint checkpoint |
| 13 | Inspector: verify `tools/call` rejection | Attempt a disallowed `tools/call` via Inspector; confirm it's rejected server-side and shows up in the audit log/metrics from Task 9–11 | 9/10/2026 | 10/10/2026 | Quân & Huy | [mcp-gateway-guideline.md §3](mcp-gateway-guideline.md); [deep-research-MCPGateWay.md](deep-research-MCPGateWay.md) | Not Started | The core PoC claim from README Status: "not just hidden" |
| 14 | Consolidate PoC results for draft report | Pull configs, screenshots, and logs from Tasks 1–13 into the draft report section | 12/10/2026 | 15/10/2026 | Quân & Huy | [README.md](../README.md) Status section | Not Started | Feeds Deadlines.md D3 milestone "bản nháp báo cáo ≥35 trang" due ~15/10 |
| 15 | Fix RBAC gaps | Address any RBAC edge cases or misconfigurations surfaced during Task 12–13 verification | 16/10/2026 | 22/10/2026 | Quân | [mcp-gateway_personal-doc.md §6](mcp-gateway_personal-doc.md) | Not Started | Scope depends on what Task 12–13 actually find |
| 16 | Fix monitoring gaps | Address any audit/tracing coverage gaps surfaced during Task 12–13 verification | 16/10/2026 | 22/10/2026 | Huy | [mcp-gateway_personal-doc.md](mcp-gateway_personal-doc.md) (Observability) | Not Started | Scope depends on what Task 12–13 actually find |
| 17 | Final joint demo run-through | Re-run the full Inspector + monitoring verification end-to-end as a dry run of the demo | 26/10/2026 | 28/10/2026 | Quân & Huy | [README.md](../README.md) Status / next milestone | Not Started | Depends on Tasks 15–16 |
| 18 | Close out docs | Update README.md Status section with actual results; finalize local-docs notes | 29/10/2026 | 4/11/2026 | Quân & Huy | [README.md](../README.md) | Not Started | Hard boundary — D3 ends 04/11/2026 |