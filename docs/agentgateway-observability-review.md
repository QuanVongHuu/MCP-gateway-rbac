# Agentgateway observability review

  ## Scope

  This review was performed against agentgateway v1.5.0 running on a local
  Kubernetes kind cluster. It covers access logs, metrics, traces, the admin UI,
  and the observable behavior of an MCP tool-level denial.

  ## Access logs

  An `AgentgatewayPolicy` attached to `agentgateway-proxy` enriches access logs
  with:

  - authenticated user
  - JWT roles
  - MCP method
  - MCP target
  - MCP tool name

  The policy is accepted and attached by the controller. Requests without JWT
  authentication appear as `user="anonymous"` and `roles=[]`.

  Successful tool calls appear with `protocol=mcp`, `http.status=200`,
  `mcp.method.name=tools/call`, `mcp.target`, and `gen_ai.tool.name`.

  The v1.5.0 CRD does not support `spec.frontend.accessLog.preset`; access-log
  attributes must be configured using fields supported by the installed CRD.

  ## Tool-level denial

  A temporary authorization probe excluded `airflow_pause_dag`. The probe policy
  was removed after testing and is not part of the committed configuration.

  Observed behavior:

  1. `tools/list` returned 20 tools instead of 21 and omitted
     `airflow_pause_dag`.
  2. A direct call to the hidden tool returned HTTP 400.
  3. The gateway access log recorded:
     - `reason=MCP`
     - `error="mcp: Unknown tool: airflow_pause_dag"`
     - `mcp.target=airflow`
     - `gen_ai.tool.name=pause_dag`
     - `duration=0ms`
  4. Data-plane metrics recorded a request with `status="400"` and
     `reason="MCP"`.
  5. MCP metrics identified `server="airflow"` and `resource="pause_dag"`.

  Therefore a denied tool is hidden during discovery, while a direct invocation
  is rejected locally by the gateway and remains observable in logs and metrics.

  ## Metrics

  Two Prometheus endpoints were reviewed:

  - Control plane: controller port 9092, `/metrics`
  - Data plane: proxy port 15020, `/metrics`

  Relevant control-plane metrics include build information and controller
  reconciliation duration.

  Relevant data-plane metrics include:

  - `agentgateway_requests_total`
  - `agentgateway_mcp_requests_total`
  - `agentgateway_request_duration_seconds`
  - `agentgateway_response_bytes_total`
  - `agentgateway_requests_shed_total`

  The labels expose the gateway, listener, route, backend, MCP server, MCP
  resource, HTTP status, and gateway reason.

  ## Traces

  OpenTelemetry tracing is supported by
  `spec.frontend.tracing`. The installed CRD supports an OTLP backend reference
  or URL, HTTP or gRPC protocol, path, filters, sampling, resource attributes,
  and span attributes.

  Tracing is not currently configured in this environment. Producing and
  viewing traces requires both:

  1. an OTLP receiver such as an OpenTelemetry Collector, Tempo, or Jaeger;
  2. an `AgentgatewayPolicy` with `frontend.tracing` pointing to that receiver.

  This review records the supported schema and the current unconfigured state
  without deploying an additional telemetry backend.

  ## Admin UI and CEL Playground

  The proxy admin UI was accessed through port 15000. In Kubernetes mode it is
  read-only and reflects the configuration delivered to the proxy over xDS.

  The UI showed:

  - Gateway `agentgateway-system/agentgateway-proxy`
  - Route `mcp/mcp`
  - Backend `mcp/mcp-backend`
  - Policy `agentgateway-system/access-logs`
  - HTTP listener and effective configuration

  The CEL Playground evaluated the role rule for
  `radar/manage_workload` using synthetic JWT context:

  - role `data_engineer`: `true`
  - role `analyst`: `false`

  The Playground evaluation does not modify Kubernetes configuration and does
  not replace an end-to-end test with a real identity provider.
