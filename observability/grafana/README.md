# Grafana allow/deny dashboard

This local observability stack turns agentgateway access logs into an audit view in Grafana.
It shows allowed and denied MCP calls and preserves the access-log dimensions needed to inspect
each event by authenticated user, JWT roles, MCP target and tool.

## Components

- **Alloy** discovers only the `agentgateway-proxy` pods and sends their stdout logs to Loki.
- **Loki** stores logs on ephemeral kind storage. Data is reset with the cluster.
- **Grafana** provisions Loki and the **MCP Gateway - Allow and Deny** dashboard automatically.

The dashboard classifies a successful `tools/call` with HTTP 200 as `allow`. A tool-level denial
is HTTP 400 with `reason=MCP` and `Unknown tool`, as observed for agentgateway v1.5.0. The policy in
`observability/access-logs/policy.yaml` adds `user`, `roles`, `mcp_target` and `mcp_tool` to each line.

## Run

The root `run.sh` installs this stack. To install or update it separately:

```bash
bash observability/grafana/up.sh
kubectl port-forward -n observability svc/grafana 3000:3000
```

Open <http://localhost:3000>, sign in with `admin` / `admin`, and select the dashboard under
**Dashboards → MCP Gateway**. Generate traffic with `bash scripts/run-tests.sh`; allow and deny
events should appear within a few seconds.

## Verify

```bash
kubectl get pods -n observability
curl -u admin:admin http://localhost:3000/api/health
curl -G http://localhost:3100/loki/api/v1/query_range \
  --data-urlencode 'query={namespace="agentgateway-system"}' \
  --data-urlencode "start=$(date -d '5 minutes ago' +%s)000000000"
```

The last command requires a separate Loki port-forward on `3100` and is intended for debugging.
