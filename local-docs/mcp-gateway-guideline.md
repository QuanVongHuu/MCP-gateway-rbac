# MCP Gateway — Deployment Guideline (agentgateway)

This project **deploys agentgateway** as released (Helm charts v1.5.0) on a local Kubernetes cluster and configures it so every caller sees and can call only the MCP tools their gateway roles allow, and every backend knows who the caller is. Keycloak is the identity provider. We write no gateway code.

- Design and reasoning: [docs/02-architecture.md](../docs/02-architecture.md)
- Backends, environment, folder layout, build order, tests, tasks, risks: [docs/03-implementation-plan.md](../docs/03-implementation-plan.md)
- This file: the commands and config for each step.

Revised 30/9/2026 after the mentor Q&A (`KT _ MASTERSHEET - Câu hỏi`): Keycloak replaces Entra ID, no Azure, the gateway defines its own roles, the backends are radar, Spark History Server MCP and OpenMetadata MCP.

**Everything below is a starting point checked against the vendors' docs, not yet run.** Field names marked *check* must be confirmed against the installed versions before use.

## 1. Install on the cluster

```bash
kind create cluster --name mcp

# Gateway API CRDs (standard channel)
export GWAPI_VERSION=1.6.0
kubectl apply --server-side --force-conflicts \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$GWAPI_VERSION/standard-install.yaml

# agentgateway CRDs + control plane, pinned
helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds \
  --create-namespace --namespace agentgateway-system --version v1.5.0
helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway \
  --namespace agentgateway-system --version v1.5.0 --wait
```

`deploy/agentgateway/gateway.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: agentgateway-proxy
  namespace: agentgateway-system
spec:
  gatewayClassName: agentgateway
  listeners:
  - protocol: HTTP
    port: 80
    name: http
    allowedRoutes:
      namespaces:
        from: All
```

```bash
kubectl apply -f deploy/agentgateway/gateway.yaml
kubectl port-forward deployment/agentgateway-proxy -n agentgateway-system 8080:80     # MCP endpoint
kubectl port-forward deployment/agentgateway-proxy -n agentgateway-system 15000       # admin UI
```

The admin UI at `http://localhost:15000/ui/` is read-only in Kubernetes mode. It shows the effective config and has a Tool Playground under MCP. Use it for debugging only.

Use the standard channel only. The experimental channel (`0.0.0-latest-dev`) changes daily.

## 2. Connect backends

We run mocks of the three MCP-ready systems, with the real tool names ([docs/03 §1](../docs/03-implementation-plan.md)): `radar`, `spark-history`, `openmetadata`. Airflow 3.x and dbt 2.0 MCP servers are planned by the company and get added later the same way.

**Each backend Service** marks its port as MCP:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: radar
  namespace: mcp
spec:
  selector:
    app: radar
  ports:
  - port: 80
    targetPort: 8000
    appProtocol: agentgateway.dev/mcp
```

**One `AgentgatewayBackend` multiplexes all of them** (`deploy/agentgateway/backend.yaml`):

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: mcp
  namespace: mcp
spec:
  mcp:
    prefixMode: Always              # check: field location. Keeps tool names stable when backends are added
    targets:
    - name: radar                   # becomes mcp.tool.target and the tool-name prefix
      static:
        backendRef:
          name: radar
        port: 80
        protocol: StreamableHTTP    # check: enum value (the docs example shows SSE)
    - name: spark-history
      static:
        backendRef:
          name: spark-history
        port: 80
        protocol: StreamableHTTP
    - name: openmetadata
      static:
        backendRef:
          name: openmetadata
        port: 80
        protocol: StreamableHTTP
```

**Route `/mcp` to it** (`deploy/agentgateway/route.yaml`):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mcp
  namespace: mcp
spec:
  parentRefs:
  - name: agentgateway-proxy
    namespace: agentgateway-system
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /mcp
    backendRefs:
    - name: mcp
      group: agentgateway.dev
      kind: AgentgatewayBackend
```

Check (build order step 2): with no auth yet, `tools/list` at `http://localhost:8080/mcp` shows every tool as `{target}_{tool}`, e.g. `radar_list_namespaces`, `openmetadata_search_metadata`.

**Adding a backend later:** a Service like the one above, a new entry under `targets`, its identity mode (§5), and rules for it (§4).

**Sessions:** stateful by default. Run one proxy replica. Before running more, read agentgateway's "Stateful MCP" page and choose session affinity or `sessionRouting: Stateless`.

## 3. Keycloak

Keycloak ≥ 26.2 (standard token exchange, §5, needs it). Scripted in `deploy/keycloak/`: a dev-mode Deployment plus a realm setup script using `kcadm.sh` or the admin REST API.

- Keycloak in namespace `keycloak`, with `KC_HOSTNAME=http://localhost:8002` so the token issuer is the same however Keycloak is reached. Reach it with `kubectl port-forward -n keycloak svc/keycloak 8002:8080`.
- Realm `mcp`.
- **Client `mcp-gateway`:** the audience, and the owner of the gateway roles as client roles: `data_admin`, `data_engineer`, `bi_engineer`, `analyst`. Confidential (client authentication on), with standard token exchange enabled; agentgateway uses its secret for token exchange (§5).
- **Client `openmetadata`:** the audience for tokens exchanged for the OpenMetadata backend.
- **Client `mcp-cli`:** public, direct access grants on (**test users only**; the password grant is not allowed in OAuth 2.1). Two mappers:
  - Audience mapper → adds `mcp-gateway` to `aud`.
  - User Client Role mapper → client `mcp-gateway`, token claim name `roles`, multivalued, added to the access token. It includes roles inherited from groups.
- **Groups**, standing in for company directory groups: `data-team` → role `data_engineer`, `bi-team` → role `bi_engineer`.
- **Test users** ([docs/03 §5](../docs/03-implementation-plan.md)): `analyst.user` (role `analyst`, direct), `engineer.user` (group `data-team`), `multi.user` (groups `data-team` and `bi-team`), `admin.user` (role `data_admin`, direct), `nobody.user` (nothing).

**Changing roles later:** a new role is a new client role on `mcp-gateway`; giving it to people is a group or user role mapping. Neither needs a gateway change until a rule uses the role.

Get a token and check its claims (build order step 3):

```bash
TOKEN=$(curl -s -X POST "http://localhost:8002/realms/mcp/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=mcp-cli -d username=multi.user -d password=multi | jq -r .access_token)
echo "$TOKEN" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | jq '{iss, aud, preferred_username, roles}'
# expect roles: ["data_engineer", "bi_engineer"]
```

## 4. Authentication and tool access

**JWT authentication on the Gateway** (`deploy/auth/jwt.yaml`). The identity-header transformation (§5) goes in this same policy:

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: jwt
  namespace: agentgateway-system
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: agentgateway-proxy
  traffic:
    jwtAuthentication:
      mode: Strict
      providers:
      - issuer: http://localhost:8002/realms/mcp
        audiences: [mcp-gateway]
        jwks:
          remote:
            jwksPath: /realms/mcp/protocol/openid-connect/certs
            cacheDuration: "5m"
            backendRef:
              group: ""
              kind: Service
              name: keycloak
              namespace: keycloak
              port: 8080
```

**Tool access on the MCP backend** (`rbac/tool-access.yaml`, the source of truth for role → tools). **The rules below are the example mapping used by the tests, not a decision** ([docs/02 §A4](../docs/02-architecture.md)); replace them with your own:

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: tool-access
  namespace: mcp
spec:
  targetRefs:
  - group: agentgateway.dev
    kind: AgentgatewayBackend
    name: mcp
  backend:
    mcp:
      authorization:
        action: Allow
        policy:
          matchExpressions:
          # analyst — OpenMetadata read tools
          - 'has(jwt.roles) && "analyst" in jwt.roles && mcp.tool.target == "openmetadata" && mcp.tool.name in ["search_metadata", "get_entity_details", "get_entity_lineage"]'
          # bi_engineer — OpenMetadata read tools + patch_entity
          - 'has(jwt.roles) && "bi_engineer" in jwt.roles && mcp.tool.target == "openmetadata" && mcp.tool.name in ["search_metadata", "get_entity_details", "get_entity_lineage", "patch_entity"]'
          # data_engineer — radar read tools, all of spark-history, OpenMetadata read tools
          - 'has(jwt.roles) && "data_engineer" in jwt.roles && mcp.tool.target == "radar" && mcp.tool.name in ["list_namespaces", "list_resources", "get_pod_logs"]'
          - 'has(jwt.roles) && "data_engineer" in jwt.roles && mcp.tool.target == "spark-history"'
          - 'has(jwt.roles) && "data_engineer" in jwt.roles && mcp.tool.target == "openmetadata" && mcp.tool.name in ["search_metadata", "get_entity_details", "get_entity_lineage"]'
          # data_admin — everything, including backends added later
          - 'has(jwt.roles) && "data_admin" in jwt.roles'
```

How to write a grant:

| Grant | Expression |
|---|---|
| A whole backend | `has(jwt.roles) && "<role>" in jwt.roles && mcp.tool.target == "<target>"` |
| Some tools of a backend | `… && mcp.tool.target == "<target>" && mcp.tool.name in ["<tool>", …]` |
| Everything, now and later | `has(jwt.roles) && "<role>" in jwt.roles` |
| Everyone (like the company's `common_user`) | Make a baseline role, assign it to the all-staff group, and grant that role |

Rules:
- Every rule checks a role, guarded by `has(jwt.roles)`.
- Rules are OR-ed, so someone with several roles gets the union.
- Pair `mcp.tool.name` with `mcp.tool.target`. Build order step 5 settles whether `mcp.tool.name` is prefixed; fix the rules if it is.
- No rule means nobody.
- When the rules change, update `tests/expected/` in the same pull request.

## 5. Caller identity at the backends

The caller's token never reaches a backend: agentgateway removes it by default. Each backend gets the caller's identity in one of two ways ([docs/02 §A5](../docs/02-architecture.md)).

### Identity headers (radar, spark-history)

Add a transformation to the JWT policy from §4. It runs after authentication, so the claims are verified:

```yaml
  traffic:
    jwtAuthentication: …                      # as in §4
    transformation:
      request:
        set:                                  # set replaces any client-sent value (check: §5 case 13 in docs/03)
        - name: x-forwarded-user
          value: "jwt.preferred_username"
        - name: x-forwarded-groups
          value: "has(jwt.roles) ? jwt.roles.join(',') : ''"    # check: CEL join support
```

Every backend receives these headers; the ones that don't use them ignore them. They are trustworthy only because the NetworkPolicy (§6) makes the gateway the only way in.

**The real radar** reads the same headers in proxy mode, then impersonates the user against the Kubernetes API, so the user's Kubernetes RBAC decides what radar shows or changes:

```yaml
# radar Helm values
auth:
  mode: proxy
  proxy:
    userHeader: X-Forwarded-User
    groupsHeader: X-Forwarded-Groups
```

The gateway roles then arrive as Kubernetes groups. Bind them to Kubernetes roles, e.g. a ClusterRoleBinding of `view` to group `data_engineer` and of `edit` to group `data_admin`.

### Token exchange (openmetadata)

agentgateway exchanges the caller's token at Keycloak for one whose audience is only `openmetadata`, and forwards that instead. First prove the exchange works against Keycloak directly:

```bash
curl -s -X POST "http://localhost:8002/realms/mcp/protocol/openid-connect/token" \
  -u "mcp-gateway:$MCP_GATEWAY_SECRET" \
  -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
  -d subject_token="$TOKEN" \
  -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
  -d audience=openmetadata | jq -r .access_token | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | jq '{aud, preferred_username}'
```

Keycloak requirements: `mcp-gateway` is confidential with standard token exchange enabled; the caller's token has `mcp-gateway` in `aud`; the `openmetadata` audience is available to `mcp-gateway` through a client scope with an Audience mapper.

Then the agentgateway policy (`deploy/identity/openmetadata.yaml`), a sketch to confirm against the v1.5 "OAuth token exchange" page:

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: openmetadata-token-exchange
  namespace: mcp
spec:
  targetRefs:                                  # check: can a policy target one MCP target, or only the whole AgentgatewayBackend?
  - group: ""
    kind: Service
    name: openmetadata
  backend:
    auth:                                      # check: exact field path
      oauthTokenExchange:
        backendRef: { name: keycloak, namespace: keycloak, port: 8080 }   # check
        tokenEndpointPath: /realms/mcp/protocol/openid-connect/token
        clientAuth:
          clientId: mcp-gateway
          secretRef: { name: mcp-gateway-client-secret }
        audiences: [openmetadata]
```

If token exchange can only be set for a whole `AgentgatewayBackend`, give `openmetadata` its own backend and route, and keep the other two multiplexed.

**The real OpenMetadata** must trust Keycloak: configure OM's authentication with Keycloak as the provider (its JWKS in OM's public key URLs), and map the token's username claim to OM users. OM's built-in roles and domains then decide what each user can see.

## 6. Network

Backends accept traffic only from agentgateway (`deploy/network/backends.yaml`):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backends-from-gateway-only
  namespace: mcp
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: agentgateway-system
```

Confirm the CNI enforces it (docs/03 §5 case 10). If `kind`'s default CNI doesn't, recreate the cluster with Calico. Without it, identity headers can be forged by any pod.

What's reachable is listed in [docs/02 §A6](../docs/02-architecture.md): only `/mcp` for clients; the admin UI and Keycloak by port-forward; backends never.

## 7. Access logs (Huy)

Add the caller, their roles and the MCP fields to every access-log line (`observability/access-logs/policy.yaml`):

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: access-logs
  namespace: agentgateway-system
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: agentgateway-proxy
  frontend:
    accessLog:
      attributes:
        add:                                           # check: which variables are available at log time
        - name: user
          expression: 'jwt.preferred_username'
        - name: roles
          expression: 'jwt.roles'
        - name: mcp_method
          expression: 'mcp.method'
        - name: mcp_target
          expression: 'mcp.tool.target'
        - name: mcp_tool
          expression: 'mcp.tool.name'
```

`frontend.accessLog` also takes a `filter` (CEL), `preset: Otel` for OpenTelemetry field names, and `otlp` to export to a collector.

Before building the allow/deny view (Task 7), find how a tool-level denial shows up (HTTP status or JSON-RPC error; [docs/02 §A7](../docs/02-architecture.md)). Audit requirements (retention, required fields) are still unconfirmed; the mentor didn't answer Q3.

## 8. Test with MCP Inspector

`npx @modelcontextprotocol/inspector` is the official reference client and stands in for an agent platform. It has three modes: web GUI (default), `--cli` (scriptable, used by `tests/inspector/`) and `--tui`. It needs Node 22.19.0+. agentgateway's own docs use version 0.21.2.

**Always point it at the gateway's `/mcp`, never at a backend.** Every request needs a token (§3). The header flag name varies by Inspector version; check `--help`.

```bash
npx @modelcontextprotocol/inspector --cli "http://localhost:8080/mcp" --transport http \
  --header "Authorization: Bearer $TOKEN" --method tools/list

npx @modelcontextprotocol/inspector --cli "http://localhost:8080/mcp" --transport http \
  --header "Authorization: Bearer $TOKEN" --method tools/call \
  --tool-name openmetadata_search_metadata --tool-arg query=customer --format json
```

For edge cases that need a hand-built request (duplicate `"name"` keys, batches, forged identity headers; docs/03 §5 cases 9 and 13), use `curl`. Send `initialize` first and reuse the returned `Mcp-Session-Id`:

```bash
curl -s http://localhost:8080/mcp \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" -H "Mcp-Session-Id: $SID" \
  -H "X-Forwarded-User: admin.user" -H "X-Forwarded-Groups: data_admin" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"radar_list_namespaces","arguments":{}}}'
# then check the radar mock's log: it must show the token's user, not admin.user
```

Protocol background, if needed: [modelcontextprotocol.io/quickstart/server](https://modelcontextprotocol.io/quickstart/server). Inspector docs: [modelcontextprotocol.io/docs/tools/inspector](https://modelcontextprotocol.io/docs/tools/inspector).

## 9. Using the real MCP servers

Swap a mock for the real server by pointing the Service (or the target) at it; the target name, rules and tests stay the same.

- **Spark History Server MCP** (Task 13, if time allows): `kubeflow/mcp-apache-spark-history-server` has a Helm chart in `deploy/kubernetes/helm/`, speaks Streamable HTTP on port 18888, and needs a Spark History Server with some event logs. It authenticates to Spark History Server with its own credentials and has no documented way to receive the caller's identity, so per-user checks there stay open.
- **radar:** `skyhook-io/radar` in proxy mode (§5), with Kubernetes RBAC bindings for the gateway roles. Its MCP endpoint is `/mcp`.
- **OpenMetadata 1.13.3:** heavy (it needs a database and a search engine). Its MCP endpoint is `/mcp` on the OM server; it needs Keycloak configured as its authentication provider (§5). Confirm the tool list for 1.13.3; it changes between versions.
- **Optional, a real MCP client with interactive login** (VS Code, Claude Code): agentgateway's MCP auth works with Keycloak. It needs the `mcp:` block in the JWT provider and the `/.well-known/oauth-*/mcp` paths on the HTTPRoute; follow agentgateway's "Set up MCP auth" guide.

## Task plan

The task table (17 tasks, 1/10 → 4/11/2026, owners and dates) is in [docs/03-implementation-plan.md §6](../docs/03-implementation-plan.md).
