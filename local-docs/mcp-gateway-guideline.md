# MCP Gateway — Deployment Guideline (agentgateway)

This project **deploys agentgateway** as released (Helm charts v1.5.0) on a local Kubernetes cluster and configures it so every caller sees and can call only the MCP tools their gateway roles allow, and every backend knows who the caller is. Keycloak is the identity provider. We write no gateway code.

- Design and reasoning: [docs/02-architecture.md](../docs/02-architecture.md)
- Backends, environment, folder layout, build order, tests, tasks, risks: [docs/03-implementation-plan.md](../docs/03-implementation-plan.md)
- This file: the commands and config for each step.

Revised 30/9/2026 after the mentor Q&A (`KT _ MASTERSHEET - Câu hỏi`): Keycloak replaces Entra ID, no Azure, the gateway defines its own roles, the backends are radar, Spark History Server MCP and OpenMetadata MCP.

Updated 9/10/2026 after running §3 to §9 on the cluster (kind v0.33.0, agentgateway v1.5.0, Keycloak 26.2.5, MCP Inspector 0.21.2). Those parts are marked **Verified**. §1 and §2 were already installed; the §2 config shown is what runs on the cluster, but the install commands in §1 were not re-run.

§3 to §8 were verified against the mocks. Since §9, the targets `radar`, `openmetadata` and `spark-history` point at the real servers; `dbt` and `airflow` are still mocks. The `seen_by_mock` checks in §5 and §8 need a mock target: use a `dbt_` or `airflow_` tool, or point a target back at its mock (§9).

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

**One `AgentgatewayBackend` multiplexes all of them** (`servers/k8s/backend.yaml`). This is the form running on the cluster, which also has the `dbt` and `airflow` mocks:

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayBackend
metadata:
  name: mcp-backend
  namespace: mcp
spec:
  mcp:
    prefixMode: Always              # keeps tool names stable when backends are added
    targets:
    - name: radar                   # becomes mcp.tool.target and the tool-name prefix
      static:
        host: radar.mcp.svc.cluster.local
        port: 80
        path: /mcp
        protocol: StreamableHTTP
    # the same block for spark-history, openmetadata, dbt and airflow
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
    - name: mcp-backend
      group: agentgateway.dev
      kind: AgentgatewayBackend
```

Check (build order step 2): with no auth yet, `tools/list` at `http://localhost:8080/mcp` shows every tool as `{target}_{tool}`, e.g. `radar_list_namespaces`, `openmetadata_search_metadata`.

**Adding a backend later:** a Service like the one above, a new entry under `targets`, its identity mode (§5), and rules for it (§4).

**Sessions:** stateful by default. Run one proxy replica. Before running more, read agentgateway's "Stateful MCP" page and choose session affinity or `sessionRouting: Stateless`.

## 3. Keycloak

**Verified 9/10/2026** with Keycloak 26.2.5. Keycloak ≥ 26.2 (standard token exchange, §5, needs it). Scripted in `deploy/keycloak/`: `keycloak.yaml` (a dev-mode Deployment and Service) and `setup-realm.sh` (builds the realm with `kcadm.sh` through `kubectl exec`).

```bash
kubectl apply -f deploy/keycloak/keycloak.yaml
kubectl rollout status deploy/keycloak -n keycloak
bash deploy/keycloak/setup-realm.sh          # about a minute; does nothing if realm mcp already exists
kubectl port-forward -n keycloak svc/keycloak 8002:80
```

- Keycloak in namespace `keycloak`, with `KC_HOSTNAME=http://localhost:8002` so the token issuer is the same however Keycloak is reached. It must be `http`, exactly as in the `issuer` of the JWT policy (§4); with `https` every token fails issuer validation.
- The Service listens on port **80** (container port 8080). Use 80 in the port-forward and in every `backendRef` to Keycloak.
- **The realm lives in dev-mode H2 files under `/opt/keycloak/data`.** The Deployment mounts an `emptyDir` there, so the realm survives a container restart (for example restarting Docker Desktop). It is lost when the pod is deleted or the Deployment rolls out; run `setup-realm.sh` again. Without the volume, every restart wipes the realm and the gateway answers 401 to everything.
- Keycloak 26 refuses the password grant with "Account is not fully set up" unless the user has a first name, last name and email. The script sets them.
- Realm `mcp`.
- **Client `mcp-gateway`:** the audience, and the owner of the gateway roles as client roles: `data_admin`, `data_engineer`, `bi_engineer`, `analyst`. Confidential (client authentication on), with standard token exchange enabled; agentgateway uses its secret for token exchange (§5).
- **Client `openmetadata`:** the audience for tokens exchanged for the OpenMetadata backend.
- **Client `mcp-cli`:** public, direct access grants on (**test users only**; the password grant is not allowed in OAuth 2.1). Two mappers:
  - Audience mapper → adds `mcp-gateway` to `aud`.
  - User Client Role mapper → client `mcp-gateway`, token claim name `roles`, multivalued, added to the access token. It includes roles inherited from groups.
- **Groups**, standing in for company directory groups: `data-team` → role `data_engineer`, `bi-team` → role `bi_engineer`.
- **Test users** ([docs/03 §5](../docs/03-implementation-plan.md)): `analyst.user` (role `analyst`, direct), `engineer.user` (group `data-team`), `multi.user` (groups `data-team` and `bi-team`), `admin.user` (role `data_admin`, direct), `nobody.user` (nothing). Each password is the part of the username before the dot (`engineer.user` / `engineer`).
- **Client scope `openmetadata-audience`:** an Audience mapper for `openmetadata`, set as a default scope of `mcp-gateway`. It makes that audience available for token exchange (§5).

**Changing roles later:** a new role is a new client role on `mcp-gateway`; giving it to people is a group or user role mapping. Neither needs a gateway change until a rule uses the role.

Get a token and check its claims (build order step 3):

```bash
TOKEN=$(curl -s -X POST "http://localhost:8002/realms/mcp/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=mcp-cli -d username=multi.user -d password=multi | jq -r .access_token)
echo "$TOKEN" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | jq '{iss, aud, preferred_username, roles}'
# expect iss http://localhost:8002/realms/mcp, aud ["mcp-gateway", "account"], roles ["bi_engineer", "data_engineer"]
# nobody.user has no roles claim at all, which is why every rule starts with has(jwt.roles)
```

## 4. Authentication and tool access

**JWT authentication on the Gateway** (`deploy/auth/jwt.yaml`, **verified 9/10/2026**: no token gets 401). The identity-header transformation (§5) goes in this same policy:

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
              port: 80              # the Service port
```

Apply with `kubectl apply -f deploy/auth/jwt.yaml` and read the output. `ACCEPTED True` from `kubectl get agentgatewaypolicy` only describes the version already on the cluster: if the apply is rejected, the old version keeps running. `kubectl diff -f deploy/auth/jwt.yaml` prints nothing when the file and the cluster agree.

**Tool access on the MCP backend** (`rbac/tool-access.yaml`, the source of truth for role → tools; **verified 9/10/2026**). **The rules below are the example mapping used by the tests, not a decision** ([docs/02 §A4](../docs/02-architecture.md)); replace them with your own:

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
    name: mcp-backend
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
          - 'has(jwt.roles) && "data_engineer" in jwt.roles && mcp.tool.target == "dbt" && mcp.tool.name in ["list_metrics", "query_metrics", "get_model_health", "get_lineage"]'
          - 'has(jwt.roles) && "data_engineer" in jwt.roles && mcp.tool.target == "airflow" && mcp.tool.name in ["list_dags", "get_dag_run", "get_task_logs"]'
          # data_admin — everything, including backends added later
          - 'has(jwt.roles) && "data_admin" in jwt.roles'
```

What each test user gets from `tools/list` with these rules:

| User | With the mocks | With the real servers (§9) | By target |
|---|---|---|---|
| `analyst.user` | 3 | 3 | openmetadata 3 |
| `engineer.user` | 16 | 30 | radar 3, openmetadata 3, dbt 4, airflow 3, and all of spark-history (3 in the mock, 17 in the real server) |
| `multi.user` | 17 | 31 | the same, plus `openmetadata_patch_entity` |
| `admin.user` | 21 | 76 | every tool |
| `nobody.user` | 0 | 0 | |

A rule that names tools keeps its size when a real server replaces a mock. A rule for a whole target (`spark-history`) or for everything (`data_admin`) grows with the server: the real radar has 32 tools, 4 in the mock.

**A denied call looks exactly like a call to a tool that does not exist:** HTTP 400 with JSON-RPC error `-32602`, `Unknown tool: radar_manage_workload`. The gateway does not reveal that a hidden tool exists. To tell the two apart, read the access log (§7).

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
- Pair `mcp.tool.name` with `mcp.tool.target`. `mcp.tool.name` is the unprefixed name: the rule for `list_namespaces` on target `radar` allows the client's call to `radar_list_namespaces`.
- No rule means nobody.
- When the rules change, update `tests/expected/` in the same pull request.

## 5. Caller identity at the backends

The caller's token never reaches a backend. Each backend gets the caller's identity in one of two ways ([docs/02 §A5](../docs/02-architecture.md)): identity headers for every target, and for `openmetadata` also a token exchanged for that backend alone.

### Identity headers (radar, spark-history)

**Verified 9/10/2026.** Add a transformation to the JWT policy from §4. It runs after authentication, so the claims are verified:

```yaml
  traffic:
    jwtAuthentication: …                      # as in §4
    transformation:                           # directly under traffic, beside jwtAuthentication
      request:
        set:                                  # set replaces any client-sent value
        - name: x-forwarded-user
          value: "jwt.preferred_username"
        - name: x-forwarded-groups
          value: "has(jwt.roles) ? jwt.roles.join(',') : ''"
```

`transformation` is a sibling of `jwtAuthentication`. Indented one level deeper, the API server rejects the file with `unknown field "spec.traffic.jwtAuthentication.transformation"` and the policy already on the cluster keeps running. That happened here: authentication worked, the mock saw `x_forwarded_user: null`, and a forged `X-Forwarded-User: admin.user` reached the backend unchanged.

What the radar mock sees once the policy is applied (test in §8):

| Request | `x_forwarded_user` | `x_forwarded_groups` | `authorization_present` |
|---|---|---|---|
| `engineer.user` token | `engineer.user` | `data_engineer` | `false` |
| same, plus forged `X-Forwarded-User: admin.user`, `X-Forwarded-Groups: data_admin` | `engineer.user` | `data_engineer` | `false` |
| `multi.user` token | `multi.user` | `bi_engineer,data_engineer` | `false` |
| forged headers, no token | 401 at the gateway; the backend is never called | | |

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

**Verified 9/10/2026.** agentgateway exchanges the caller's token at Keycloak for one whose audience is only `openmetadata`, and forwards that instead. First prove the exchange works against Keycloak directly:

```bash
export MSYS_NO_PATHCONV=1      # Git Bash on Windows only
kc() { kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@"; }
kc config credentials --server http://localhost:8080 --realm master --user admin --password admin
GW=$(kc get clients -r mcp -q clientId=mcp-gateway --fields id --format csv --noquotes | tr -d '\r')
MCP_GATEWAY_SECRET=$(kc get clients/$GW/client-secret -r mcp --fields value --format csv --noquotes | tr -d '\r')

curl -s -X POST "http://localhost:8002/realms/mcp/protocol/openid-connect/token" \
  -u "mcp-gateway:$MCP_GATEWAY_SECRET" \
  -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
  -d subject_token="$TOKEN" \
  -d subject_token_type=urn:ietf:params:oauth:token-type:access_token \
  -d audience=openmetadata | jq -r .access_token | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | jq '{aud, preferred_username}'
# expect {"aud": "openmetadata", "preferred_username": "<the caller>"}
```

Keycloak requirements: `mcp-gateway` is confidential with standard token exchange enabled; the caller's token has `mcp-gateway` in `aud`; the `openmetadata` audience is available to `mcp-gateway` through a client scope with an Audience mapper (§3). Without that scope Keycloak answers `Requested audience not available: openmetadata`. The exchanged token has `azp: mcp-gateway` and no `roles` claim.

**The gateway needs the client secret** as a Secret with the key `clientSecret`, in the policy's namespace. It is not in git:

```bash
kubectl create secret generic mcp-gateway-client-secret -n mcp --from-literal=clientSecret="$MCP_GATEWAY_SECRET"
```

Rebuilding the realm generates a new secret: delete this Secret and create it again.

**The policy** (`deploy/identity/openmetadata.yaml`). `sectionName` is the target's name inside the `AgentgatewayBackend`, so the exchange applies to `openmetadata` only and it stays multiplexed with the others:

```yaml
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: openmetadata-token-exchange
  namespace: mcp
spec:
  targetRefs:
  - group: agentgateway.dev
    kind: AgentgatewayBackend
    name: mcp-backend
    sectionName: openmetadata
  backend:
    auth:
      oauthTokenExchange:
        backendRef:
          name: keycloak
          namespace: keycloak
          port: 80
        path: /realms/mcp/protocol/openid-connect/token
        subjectToken:                          # where the caller's token is; see below
          source:
            header:
              name: x-caller-token
              prefix: "Bearer "
        clientAuth:
          clientId: mcp-gateway
          secretRef:
            name: mcp-gateway-client-secret
        audiences: [openmetadata]
```

**Getting the caller's token to the exchange without leaking it.** JWT authentication deletes the token from the request as soon as it is validated. The exchange then finds nothing, and because the gateway initializes every target, `initialize` fails with 500 for every caller (`oauth token exchange subject token missing` in the proxy's debug log). `preserveToken: true` fixes the exchange but sends the caller's token to every backend. So `deploy/auth/jwt.yaml` does three things:

```yaml
  traffic:
    jwtAuthentication:
      mode: Strict
      preserveToken: true                     # keep the token long enough to move it
      providers: …
    transformation:
      request:
        set:
        - …                                   # x-forwarded-user, x-forwarded-groups as above
        - name: x-caller-token                # private copy for the exchange
          value: 'request.headers["authorization"]'
        remove: [authorization]
---
apiVersion: agentgateway.dev/v1alpha1
kind: AgentgatewayPolicy
metadata:
  name: strip-caller-token
  namespace: mcp
spec:
  targetRefs:
  - group: agentgateway.dev
    kind: AgentgatewayBackend
    name: mcp-backend                         # every target
  backend:
    transformation:
      request:
        remove: [x-caller-token]              # runs after the exchange has read it
```

The backend transformation runs after backend auth, so the exchange reads `x-caller-token` and the header is gone before the request leaves the gateway. A new target gets no token unless it has its own exchange policy. **Apply the two policies in `jwt.yaml` together**: without `strip-caller-token`, every backend receives the caller's token in `x-caller-token`.

What the backends receive (mock `seen_by_mock`, and a packet capture inside the pods):

| Target | `Authorization` | `x-caller-token` | identity headers |
|---|---|---|---|
| `openmetadata` | exchanged token: `aud` `openmetadata`, `azp` `mcp-gateway`, the caller's `preferred_username` | absent | present |
| `radar` (and the other targets) | absent | absent | present |

A client-sent `X-Caller-Token` is overwritten like the other identity headers.

To see why a call fails inside the gateway, raise the proxy's log level for a moment:

```bash
kubectl port-forward deployment/agentgateway-proxy -n agentgateway-system 15000 &
curl -s -X POST "http://localhost:15000/logging?level=debug"     # then level=info to go back
kubectl logs -n agentgateway-system deploy/agentgateway-proxy --since=30s
```

**The real OpenMetadata** must trust Keycloak: configure OM's authentication with Keycloak as the provider (its JWKS in OM's public key URLs), and map the token's username claim to OM users. OM's built-in roles and domains then decide what each user can see.

## 6. Network

**Verified 9/10/2026.** Backends accept traffic only from agentgateway (`deploy/network/backends.yaml`):

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

kind's default CNI (kindnet, kind v0.33.0) enforces it; Calico is not needed. The policy covers every pod in `mcp`, so pods there cannot call each other either.

Without it, identity headers can be forged by any pod. Before the policy was applied, a pod in namespace `default` called radar's `manage_workload` directly with `X-Forwarded-User: admin.user`, and the mock accepted it as `admin.user`: a write tool that `engineer.user` is denied at the gateway. To repeat the test (docs/03 §5 case 10), run a pod outside the gateway and try to reach a backend; it must time out:

```bash
kubectl run probe -n default --image=mcp-mocks:dev --image-pull-policy=Never --restart=Never --rm -i --command -- \
  python -c "import urllib.request; urllib.request.urlopen('http://radar.mcp.svc.cluster.local/mcp', timeout=6)"
# expect: URLError timed out. Repeat with -n mcp. Without the policy the backend answers (an HTTP error, not a timeout).
```

What's reachable is listed in [docs/02 §A6](../docs/02-architecture.md): only `/mcp` for clients; the admin UI and Keycloak by port-forward; backends never.

## 7. Access logs (Huy)

**Verified 9/10/2026.** Add the caller, their roles and the MCP fields to every access-log line (`observability/access-logs/policy.yaml`):

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
        add:                                           # each guarded with has(): not every request has a token or a tool
        - name: user
          expression: 'has(jwt.preferred_username) ? jwt.preferred_username : "anonymous"'
        - name: roles
          expression: 'has(jwt.roles) ? jwt.roles : []'
        - name: mcp_method
          expression: 'has(mcp.methodName) ? mcp.methodName : ""'
        - name: mcp_target
          expression: 'has(mcp.tool.target) ? mcp.tool.target : ""'
        - name: mcp_tool
          expression: 'has(mcp.tool.name) ? mcp.tool.name : ""'
```

`frontend.accessLog` also takes a `filter` (CEL), `preset: Otel` for OpenTelemetry field names, and `otlp` to export to a collector.

Read the lines with `kubectl logs -n agentgateway-system deploy/agentgateway-proxy | grep "request "`. The added attributes come last on each line:

| Call | `http.status` | Added attributes | Also on the line |
|---|---|---|---|
| allowed `tools/call` | 200 | `user="multi.user" roles=["bi_engineer", "data_engineer"] mcp_method="tools/call" mcp_target="radar" mcp_tool="list_namespaces"` | |
| denied `tools/call` | 400 | `user="engineer.user" roles=["data_engineer"] mcp_method="tools/call" mcp_target="radar" mcp_tool="manage_workload"` | `error="mcp: Unknown tool: radar_manage_workload" reason=MCP` |
| no token | 401 | `user="anonymous" roles=[] mcp_method=""` | `error="authentication failure: no bearer token found" reason=JwtAuth` |

So the allow/deny view (Task 7) is: `mcp_method="tools/call"` with status 200 is allowed; status 400 with `reason=MCP` and an `Unknown tool` error is a denial or a mistyped tool name. Audit requirements (retention, required fields) are still unconfirmed; the mentor didn't answer Q3.

## 8. Test with MCP Inspector

`npx @modelcontextprotocol/inspector` is the official reference client and stands in for an agent platform. It has three modes: web GUI (default), `--cli` (scriptable, used by `tests/inspector/`) and `--tui`. It needs Node 22.19.0+. agentgateway's own docs use version 0.21.2.

**The checks in this section are scripted:** `scripts/run-tests.sh` runs `tests/curl/run.sh` (the hand-built cases below) and `tests/inspector/run.sh` (each user's `tools/list` and a set of allowed and denied calls) and compares the results with `tests/expected/`. `scripts/get-token.sh <user>` prints a token, and `scripts/up.sh` applies §2 to §7 in order.

**Always point it at the gateway's `/mcp`, never at a backend.** Every request needs a token (§3). **Verified 9/10/2026** with Inspector 0.21.2; the output is JSON already, and `--format json` is rejected.

```bash
npx -y @modelcontextprotocol/inspector@0.21.2 --cli "http://localhost:8080/mcp" --transport http \
  --header "Authorization: Bearer $TOKEN" --method tools/list

npx -y @modelcontextprotocol/inspector@0.21.2 --cli "http://localhost:8080/mcp" --transport http \
  --header "Authorization: Bearer $TOKEN" --method tools/call \
  --tool-name openmetadata_search_metadata --tool-arg query=customer
```

For edge cases that need a hand-built request (duplicate `"name"` keys, batches, forged identity headers; docs/03 §5 cases 9 and 13), use `curl`. Send `initialize` first and reuse the returned `Mcp-Session-Id`. The gateway answers as an event stream, so the JSON is on the `data:` line, and the tool result is JSON text inside `result.content[0].text`.

The forged-header test (**verified 9/10/2026**; expected results in §5):

```bash
TOKEN=$(curl -s -X POST "http://localhost:8002/realms/mcp/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=mcp-cli -d username=engineer.user -d password=engineer | jq -r .access_token)
B=(-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")

SID=$(curl -si http://localhost:8080/mcp -H "Authorization: Bearer $TOKEN" "${B[@]}" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}' \
  | grep -i '^mcp-session-id' | awk '{print $2}' | tr -d '\r')
H=(-H "Authorization: Bearer $TOKEN" "${B[@]}" -H "Mcp-Session-Id: $SID")
curl -s http://localhost:8080/mcp "${H[@]}" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'

CALL='{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"radar_list_namespaces","arguments":{}}}'
seen() { grep '^data:' | sed 's/^data: //' | jq -r '.result.content[0].text' | jq -c .seen_by_mock; }

# 1. as engineer.user
curl -s http://localhost:8080/mcp "${H[@]}" -d "$CALL" | seen
# 2. the same call with forged headers: the mock must still show engineer.user
curl -s http://localhost:8080/mcp "${H[@]}" \
  -H "X-Forwarded-User: admin.user" -H "X-Forwarded-Groups: data_admin" -d "$CALL" | seen
# 3. the same records on the backend side
kubectl logs -n mcp deploy/radar --tail=30 | grep tool_call
# forged headers without a token: expect 401
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/mcp "${B[@]}" -H "X-Forwarded-User: admin.user" -d "$CALL"
```

The two attempts to slip a denied tool past the authorization check, as `engineer.user` (**verified 9/10/2026**; neither reaches a backend):

| Request | Result |
|---|---|
| `"params"` with two `"name"` keys, one allowed and one denied, in either order | HTTP 500, `invalid params for method: tools/call` |
| A JSON-RPC batch (an array) with an allowed and a denied call | HTTP 400, `fail to deserialize request body` |

Protocol background, if needed: [modelcontextprotocol.io/quickstart/server](https://modelcontextprotocol.io/quickstart/server). Inspector docs: [modelcontextprotocol.io/docs/tools/inspector](https://modelcontextprotocol.io/docs/tools/inspector).

## 9. Using the real MCP servers

**Verified 9/10/2026** for radar, OpenMetadata and Spark History Server MCP. Swap a mock for the real server by changing `host` and `port` of its target in `deploy/agentgateway/AgentgatewayBackend.yaml`; the target name, rules and tests stay the same. Files, start commands and how to go back to a mock: [deploy/real-servers/](../deploy/real-servers/README.md).

| Target | Real server | Runs in | Target `host:port` | MCP tools |
|---|---|---|---|---|
| `radar` | skyhook-io/radar 1.16.0 | kind, namespace `mcp`, Helm release `radar-real` | `radar-real.mcp.svc.cluster.local:9280` | 32 |
| `openmetadata` | OpenMetadata 1.13.3 | Docker | `openmetadata-real:8585` | 17 |
| `spark-history` | kubeflow Spark History Server MCP 1.0.1 | Docker | `spark-history-real:18888` | 17 |

Radar runs inside the cluster because it trusts the identity headers, and only the NetworkPolicy (§6) stops other pods from forging them. The other two run in Docker, on Docker's `kind` network, which pods can reach by container name. **The NetworkPolicy does not cover them**: every pod can call them directly.

**One target down breaks everyone.** The gateway initializes every target, so if one is unreachable or answers an error, `initialize` fails for all callers. Start the Docker containers before using the gateway.

- **radar** (`deploy/real-servers/radar/`): `auth.mode: proxy`. Radar's own ServiceAccount is read-only plus `impersonate`; every call runs as the caller's user and groups, so Kubernetes RBAC decides. `rbac.yaml` binds group `data_engineer` to ClusterRole `view` and `data_admin` to `edit`.
  - `engineer.user` listing Secrets gets an empty list; `admin.user` gets them. `admin.user`'s `manage_workload` restart of a Deployment really happened; for `engineer.user` the tool is hidden at the gateway.
  - `edit` can read Secrets cluster-wide, including `mcp-gateway-client-secret`. Narrow the binding outside a lab.
- **OpenMetadata 1.13.3** (`deploy/real-servers/openmetadata/`): the release's `docker-compose-postgres.yml` unchanged, plus an override. About 3 GB of memory with the ingestion service left out. The MCP endpoint is built in at `/mcp`.
  - It trusts Keycloak with `AUTHENTICATION_PROVIDER: custom-oidc`, Keycloak's JWKS URL in `AUTHENTICATION_PUBLIC_KEYS` (reached through a NodePort, `keycloak-nodeport.yaml`) and `preferred_username` as the principal claim.
  - A user must exist in OpenMetadata before their token is accepted; unknown users get 404. `setup.sh` creates the test users as `admin.user`, who is an OpenMetadata admin through `AUTHORIZER_ADMIN_PRINCIPALS`.
  - Per-user identity works end to end: `multi.user` edited a table description with `openmetadata_patch_entity` through the gateway, and OpenMetadata recorded `updatedBy: multi.user`.
  - **It does not check the token's audience.** It accepted a caller's original token (`aud: mcp-gateway`) sent to it directly. The exchange limits what the gateway hands over; OpenMetadata does not enforce it.
  - Tool arguments differ from the mock: `patch_entity` takes `fqn`.
- **Spark History Server MCP 1.0.1** (`deploy/real-servers/spark-history/`): the image tag is `1.0.1`, without `v`. It runs with a Spark History Server (`apache/spark:3.5.5`) on the upstream project's three sample event logs.
  - It has no authentication and cannot receive the caller's identity; the gateway's tool rules are the only control. Use non-sensitive event logs.
  - Its DNS-rebinding protection answers 421 `Invalid Host header` unless the gateway's host is in `SHS_MCP__TRANSPORT_SECURITY__ALLOWED_HOSTS`. The gateway sends the host without a port.
- **Optional, a real MCP client with interactive login** (VS Code, Claude Code): agentgateway's MCP auth works with Keycloak. It needs the `mcp:` block in the JWT provider and the `/.well-known/oauth-*/mcp` paths on the HTTPRoute; follow agentgateway's "Set up MCP auth" guide.

## Task plan

The task table (17 tasks, 1/10 → 4/11/2026, owners and dates) is in [docs/03-implementation-plan.md §6](../docs/03-implementation-plan.md).
