# observability/access-logs

**What:** the audit trail: every gateway log line carries who called what.

**Contains:**
- `policy.yaml`: an `AgentgatewayPolicy` on the Gateway using the OpenTelemetry preset and custom `agent_id`, `agent_roles`, `mcp_method`, `mcp_target` and `mcp_tool` attributes.

**README mapping:** *Audit* checkpoint. Build step 7, guideline §7.

**Open questions:** live output for tool-level denials, audit retention, OTLP destination and required production fields.

**Check:** a denied and an allowed call each produce a log line with the right user, roles and tool.
