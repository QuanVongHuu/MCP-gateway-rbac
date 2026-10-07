# observability/access-logs

**What:** the audit trail: every gateway log line carries who called what.

**Contains (planned):**
- `policy.yaml`: an `AgentgatewayPolicy` on the Gateway with `frontend.accessLog` attributes `user`, `roles`, `mcp_method`, `mcp_target`, `mcp_tool` (optionally a `filter`, `preset: Otel`, or `otlp` export).

**README mapping:** *Audit* checkpoint. Build step 7, guideline §7.

**Open questions:** which variables are available at log time (*check*), how a tool-level denial appears (HTTP status or JSON-RPC error), and audit retention/required fields (mentor Q3, unanswered).

**Check:** a denied and an allowed call each produce a log line with the right user, roles and tool.
