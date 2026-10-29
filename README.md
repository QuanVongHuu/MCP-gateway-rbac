# MCP Gateway RBAC

Deploys [agentgateway](https://agentgateway.dev) (Helm charts v1.5.0) on a local Kubernetes cluster so that:

- every caller sees and can call **only the MCP tools their role allows**, and
- every backend **knows who the caller is**.

Keycloak is the identity provider. **We write no gateway code**: the project is configuration (YAML), mock backends and tests.

> **Status:** the complete AI Agent MVP has been validated on kind: Keycloak service identities, strict JWT authentication, role-based tool discovery/calls, backend identity headers, NetworkPolicy and audit fields. All 10 Agent × Tool test profiles pass. See `evidence/agent-rbac-smoke.txt`. Real backend integration and delegated human identity remain future work.

## Architecture

```mermaid
flowchart LR
    client["MCP client<br/>(Inspector, agent)"]

    subgraph k8s["Kubernetes (kind)"]
        subgraph kc["ns: keycloak"]
            keycloak["Keycloak<br/>realm: mcp"]
        end

        subgraph gw["ns: agentgateway-system"]
            proxy["agentgateway-proxy<br/>1. JWT auth<br/>2. tool RBAC<br/>3. identity<br/>4. access log"]
        end

        subgraph mcp["ns: mcp (NetworkPolicy: only the gateway may connect)"]
            backend["AgentgatewayBackend 'mcp-backend'<br/>multiplexes 5 targets"]
            radar["radar"]
            spark["spark-history"]
            om["openmetadata"]
            dbt["dbt"]
            airflow["airflow"]
        end
    end

    client -- "1. get token" --> keycloak
    client -- "2. /mcp + Bearer token" --> proxy
    proxy -. "JWKS (verify signature)" .-> keycloak
    proxy --> backend
    backend --> radar
    backend --> spark
    backend --> om
    backend --> dbt
    backend --> airflow
    proxy -. "token exchange (openmetadata only)" .-> keycloak
```

Request sequence for one tool call:

```mermaid
sequenceDiagram
    autonumber
    participant C as MCP client
    participant K as Keycloak
    participant G as agentgateway
    participant B as Backend (e.g. radar)

    C->>K: login (user, password)
    K-->>C: access token (aud=mcp-gateway, roles=[...])
    C->>G: tools/call radar_list_namespaces + Bearer token
    G->>K: fetch JWKS (cached)
    G->>G: verify signature, issuer, audience
    G->>G: tool RBAC: any rule matching roles + target + tool?
    alt no rule matches
        G-->>C: denied
    else allowed
        G->>B: call list_namespaces + x-forwarded-user / groups (token removed)
        B-->>G: result
        G-->>C: result
    end
    G->>G: access log: user, roles, mcp target, tool
```

A request passes through a chain of checkpoints, and each one answers a different question:

| Checkpoint | Question | Where it lives |
|---|---|---|
| Network | Can this pod reach the backend at all? | `deploy/network/` |
| Authentication | Is the token genuine, for this audience? | `deploy/keycloak/`, `deploy/auth/` |
| Authorization | May this role call this tool? | `rbac/tool-access.yaml` |
| Identity | What does the backend learn about the caller? | `deploy/auth/` (headers), `deploy/identity/` (token exchange) |
| Audit | What happened, and who did it? | `observability/access-logs/` |

### Key behaviours

- **One endpoint.** Clients only talk to `/mcp` on the gateway. Tools from all backends appear as `{target}_{tool}`, e.g. `radar_list_namespaces`, `openmetadata_search_metadata`.
- **AI Agent capabilities live in Keycloak** as client roles on `mcp-gateway` (for example `kube_viewer`, `metadata_editor`, `airflow_operator`) and arrive in the token's `roles` claim.
- **Rules are OR-ed.** Someone with several roles gets the union. No matching rule means no access.
- **The caller's token never reaches a backend.** Backends get identity either by headers (`x-forwarded-user`, `x-forwarded-groups`) or by an exchanged token scoped to that backend (OpenMetadata).
- **Backends are reachable only through the gateway**, which is what makes the identity headers trustworthy.

## Folder structure

```
deploy/            everything `kubectl apply`-able, one folder per concern
  cluster/           kind config (Calico if the default CNI doesn't enforce NetworkPolicy)
  agentgateway/      Gateway, AgentgatewayBackend, HTTPRoute
  keycloak/          dev-mode Deployment + realm setup script
  auth/              JWT authentication + identity-header transformation
  identity/          token exchange for backends that need it
  network/           NetworkPolicy: backends accept only the gateway
rbac/
  tool-access.yaml   source of truth: role -> tools
servers/           mock MCP backends, one folder per target name
  radar/  spark-history/  openmetadata/  dbt/  airflow/
observability/
  access-logs/       caller, roles and MCP fields on every log line
tests/
  expected/          the role x tool allow/deny matrix, as data
  inspector/         scripted MCP Inspector calls per test user
  curl/              hand-built edge cases (forged headers, batches)
scripts/           get a token, run all tests
docs/              architecture and implementation plan
local-docs/        deployment guideline (commands per step) and personal notes
evidence/          screenshots/logs for the report
```

Each folder matches one checkpoint or build step, so a failing test points to one folder. Policy (`rbac/`) is kept apart from infrastructure (`deploy/`) because it changes often and needs its own review trail.

## How to leverage it

Follow the build order in [local-docs/mcp-gateway-guideline.md](local-docs/mcp-gateway-guideline.md). Verify each layer before adding the next:

1. **Install** the Gateway API CRDs, agentgateway and the `Gateway` (guideline §1). Check: the proxy is running and port-forward to `8080` works.
2. **Connect backends** (§2). Check: with no auth, `tools/list` at `http://localhost:8080/mcp` shows every tool as `{target}_{tool}`.
3. **Keycloak**. Check: every AI Agent service account token has `aud=mcp-gateway`, its own `azp`, and only its expected capability roles.
4. **Auth and tool access**. Check: no token is rejected, and each test agent sees only its expected tools.
5. **Caller identity** (§5). Check: the radar mock logs the token's user, not a forged header.
6. **Network** (§6). Check: a pod outside the gateway cannot reach a backend.
7. **Access logs** (§7), then **test with MCP Inspector** (§8).

### Common changes

| I want to... | Change |
|---|---|
| Give a role access to more tools | Edit `rbac/tool-access.yaml`, **and** `tests/expected/` in the same PR |
| Add a new role | New client role on `mcp-gateway` in Keycloak; add a rule only when it needs access |
| Put someone in a role | Group or user role mapping in Keycloak. No gateway change |
| Add a backend (e.g. Airflow, dbt) | `servers/<name>/`, a Service with `appProtocol: agentgateway.dev/mcp`, a new entry under `targets`, an identity mode, rules and tests |
| Swap a mock for the real server | Point the Service at it. Target name, rules and tests stay the same |

Keep the target name identical across the backend target, the tool prefix, the RBAC rule, `servers/<name>/` and the tests.

### AI Agent identities

The initial service accounts and their role-to-tool matrix are defined in [AI Agent Tool Access](docs/ai-agent-tool-access.md) and machine-readable form in `tests/expected/agent-tool-access.json`. Each agent uses OAuth client credentials and has a distinct confidential Keycloak client.

### Trying it

Always point clients at the gateway's `/mcp`, never at a backend, and send a token:

```bash
npx @modelcontextprotocol/inspector --cli "http://localhost:8080/mcp" --transport http \
  --header "Authorization: Bearer $TOKEN" --method tools/list
```

The admin UI at `http://localhost:15000/ui/` is read-only and for debugging only.

## Requirements

`kind`, `kubectl`, `helm`, Python 3.13 with `mcp==1.30.0`, Node 22.19+ (MCP Inspector), `curl`, `jq`. Keycloak ≥ 26.2.

## Docs

- [AI Agent Tool Access](docs/ai-agent-tool-access.md): identities, capability roles and the 21-tool authorization matrix
- [Implementation plan](docs/idea.md): phased rollout and acceptance criteria
- [Legacy deployment guideline](local-docs/mcp-gateway-guideline.md): older design notes; validate all fields marked *check*
