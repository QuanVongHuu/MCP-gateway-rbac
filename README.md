<div align="center">

# MCP Gateway RBAC

**One authenticated, role-filtered MCP endpoint for every AI agent and every tool.**

<p>
  <a href="https://agentgateway.dev"><img src="https://img.shields.io/badge/agentgateway-v1.5.0-7B3FE4?style=for-the-badge&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMzE1IiBoZWlnaHQ9IjMxNSIgdmlld0JveD0iMjUwIDI1MCA1NjUgNTY1IiBmaWxsPSJub25lIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8cGF0aCBkPSJNNTMyLjg2IDM5MC44MzFDNTcxLjY4NCAzOTAuODMxIDYwMy4xNTcgMzU5LjQ4MSA2MDMuMTU3IDMyMC44MDlDNjAzLjE1NyAyODIuMTM2IDU3MS42ODQgMjUwLjc4NiA1MzIuODYgMjUwLjc4NkM0OTQuMDM2IDI1MC43ODYgNDYyLjU2MiAyODIuMTM2IDQ2Mi41NjIgMzIwLjgwOUM0NjIuNTYyIDM1OS40ODEgNDk0LjAzNiAzOTAuODMxIDUzMi44NiAzOTAuODMxWiIgZmlsbD0iIzc3MzRiZSIvPgo8cGF0aCBkPSJNNTMyLjg2IDYwMi4yNjhDNTcxLjY4NCA2MDIuMjY4IDYwMy4xNTcgNTcwLjkxOCA2MDMuMTU3IDUzMi4yNDZDNjAzLjE1NyA0OTMuNTczIDU3MS42ODQgNDYyLjIyMyA1MzIuODYgNDYyLjIyM0M0OTQuMDM2IDQ2Mi4yMjMgNDYyLjU2MiA0OTMuNTczIDQ2Mi41NjIgNTMyLjI0NkM0NjIuNTYyIDU3MC45MTggNDk0LjAzNiA2MDIuMjY4IDUzMi44NiA2MDIuMjY4WiIgZmlsbD0iIzc3MzRiZSIvPgo8cGF0aCBkPSJNNTczLjEwOSA0MjYuNDMxQzU3My4xMDkgNDAxLjE5OSA1ODAuMzc0IDM3Ny41MzIgNTkyLjc0NSAzNTcuMzg2TDUzMi44NTUgMzIwLjYxNEw0NzIuOTY1IDM1Ny4zODZDNDg1LjMzNiAzNzcuNTMyIDQ5Mi42MDEgNDAxLjAwMyA0OTIuNjAxIDQyNi40MzFDNDkyLjYwMSA0NTEuODU4IDQ4NS4zMzYgNDc1LjMyOSA0NzIuOTY1IDQ5NS40NzVMNTMyLjg1NSA1MzIuMjQ3TDU5Mi43NDUgNDk1LjQ3NUM1ODAuMzc0IDQ3NS4zMjkgNTczLjEwOSA0NTEuODU4IDU3My4xMDkgNDI2LjQzMVoiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTcwNS40NTMgNDk2LjQ1MkM3NDQuMjc3IDQ5Ni40NTIgNzc1Ljc1IDQ2NS4xMDEgNzc1Ljc1IDQyNi40MjlDNzc1Ljc1IDM4Ny43NTYgNzQ0LjI3NyAzNTYuNDA2IDcwNS40NTMgMzU2LjQwNkM2NjYuNjI5IDM1Ni40MDYgNjM1LjE1NiAzODcuNzU2IDYzNS4xNTYgNDI2LjQyOUM2MzUuMTU2IDQ2NS4xMDEgNjY2LjYyOSA0OTYuNDUyIDcwNS40NTMgNDk2LjQ1MloiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTcwNS40NTMgNzA3Ljg4OUM3NDQuMjc3IDcwNy44ODkgNzc1Ljc1IDY3Ni41MzggNzc1Ljc1IDYzNy44NjZDNzc1Ljc1IDU5OS4xOTQgNzQ0LjI3NyA1NjcuODQzIDcwNS40NTMgNTY3Ljg0M0M2NjYuNjI5IDU2Ny44NDMgNjM1LjE1NiA1OTkuMTk0IDYzNS4xNTYgNjM3Ljg2NkM2MzUuMTU2IDY3Ni41MzggNjY2LjYyOSA3MDcuODg5IDcwNS40NTMgNzA3Ljg4OVoiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTc0NS43MDMgNTMyLjI0NkM3NDUuNzAzIDUwNy4wMTQgNzUyLjk2OCA0ODMuMzQ4IDc2NS4zMzkgNDYzLjIwMUw3MDUuNDQ5IDQyNi40M0w2NDUuNTU5IDQ2My4yMDFDNjU3LjkyOSA0ODMuMzQ4IDY2NS4xOTUgNTA2LjgxOSA2NjUuMTk1IDUzMi4yNDZDNjY1LjE5NSA1NTcuNjczIDY1Ny45MjkgNTgxLjE0NSA2NDUuNTU5IDYwMS4yOTFMNzA1LjQ0OSA2MzguMDYyTDc2NS4zMzkgNjAxLjI5MUM3NTIuOTY4IDU4MS4xNDUgNzQ1LjcwMyA1NTcuNjczIDc0NS43MDMgNTMyLjI0NloiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTM2MC4wNTkgNDk2LjQ1MkMzOTguODgzIDQ5Ni40NTIgNDMwLjM1NiA0NjUuMTAxIDQzMC4zNTYgNDI2LjQyOUM0MzAuMzU2IDM4Ny43NTYgMzk4Ljg4MyAzNTYuNDA2IDM2MC4wNTkgMzU2LjQwNkMzMjEuMjM1IDM1Ni40MDYgMjg5Ljc2MiAzODcuNzU2IDI4OS43NjIgNDI2LjQyOUMyODkuNzYyIDQ2NS4xMDEgMzIxLjIzNSA0OTYuNDUyIDM2MC4wNTkgNDk2LjQ1MloiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTM2MC4wNTkgNzA3Ljg4N0MzOTguODgzIDcwNy44ODcgNDMwLjM1NiA2NzYuNTM3IDQzMC4zNTYgNjM3Ljg2NUM0MzAuMzU2IDU5OS4xOTIgMzk4Ljg4MyA1NjcuODQyIDM2MC4wNTkgNTY3Ljg0MkMzMjEuMjM1IDU2Ny44NDIgMjg5Ljc2MiA1OTkuMTkyIDI4OS43NjIgNjM3Ljg2NUMyODkuNzYyIDY3Ni41MzcgMzIxLjIzNSA3MDcuODg3IDM2MC4wNTkgNzA3Ljg4N1oiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTQwMC4zMDggNTMyLjI0NUM0MDAuMzA4IDUwNy4wMTMgNDA3LjU3MyA0ODMuMzQ2IDQxOS45NDQgNDYzLjJMMzYwLjA1NCA0MjYuNDI4TDMwMC4xNjQgNDYzLjJDMzEyLjUzNSA0ODMuMzQ2IDMxOS44IDUwNi44MTcgMzE5LjggNTMyLjI0NUMzMTkuOCA1NTcuNjcyIDMxMi41MzUgNTgxLjE0MyAzMDAuMTY0IDYwMS4yODlMMzYwLjA1NCA2MzguMDYxTDQxOS45NDQgNjAxLjI4OUM0MDcuNTczIDU4MS4xNDMgNDAwLjMwOCA1NTcuNjcyIDQwMC4zMDggNTMyLjI0NVoiIGZpbGw9IiM3NzM0YmUiLz4KPHBhdGggZD0iTTUzMi44NiA4MTMuNTExQzU3MS42ODQgODEzLjUxMSA2MDMuMTU3IDc4Mi4xNiA2MDMuMTU3IDc0My40ODhDNjAzLjE1NyA3MDQuODE2IDU3MS42ODQgNjczLjQ2NSA1MzIuODYgNjczLjQ2NUM0OTQuMDM2IDY3My40NjUgNDYyLjU2MiA3MDQuODE2IDQ2Mi41NjIgNzQzLjQ4OEM0NjIuNTYyIDc4Mi4xNiA0OTQuMDM2IDgxMy41MTEgNTMyLjg2IDgxMy41MTFaIiBmaWxsPSIjNzczNGJlIi8%2BCjwvc3ZnPgo%3D" alt="agentgateway"></a>
  <a href="https://modelcontextprotocol.io"><img src="https://img.shields.io/badge/MCP-Streamable_HTTP-000000?style=for-the-badge&logo=modelcontextprotocol&logoColor=white" alt="MCP"></a>
  <a href="https://www.keycloak.org"><img src="https://img.shields.io/badge/Keycloak-26.2-4D4D4D?style=for-the-badge&logo=keycloak&logoColor=white" alt="Keycloak"></a>
  <img src="https://img.shields.io/badge/OAuth_2.0-JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white" alt="JWT">
</p>
<p>
  <a href="https://kind.sigs.k8s.io"><img src="https://img.shields.io/badge/Kubernetes-kind-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"></a>
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm">
  <img src="https://img.shields.io/badge/Grafana-Loki_·_Alloy-F46800?style=for-the-badge&logo=grafana&logoColor=white" alt="Grafana">
</p>
<p>
  <img src="https://img.shields.io/badge/Python-FastMCP-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Apache_Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white" alt="Airflow">
  <img src="https://img.shields.io/badge/Apache_Spark-E25A1C?style=for-the-badge&logo=apachespark&logoColor=white" alt="Spark">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/PowerShell-WSL-5391FE?style=for-the-badge&logo=data:image/svg%2Bxml;base64,PHN2ZyBmaWxsPSJ3aGl0ZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWw6c3BhY2U9InByZXNlcnZlIiB2aWV3Qm94PSIwIDAgMTI4IDEyOCI%2BPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMTI0LjkxMiAxOS4zNThjLS45NjItMS4xOTktMi40MjItMS44NTgtNC4xMTEtMS44NThoLTkyLjYxYy0zLjM5NyAwLTYuNjY1IDIuNjQyLTcuNDQ0IDYuMDE1TDIuMTYyIDEwNC4wMjJjLS4zOTYgMS43MTEtLjA1OCAzLjM5NC45MjYgNC42MTkuOTYzIDEuMTk5IDIuNDIzIDEuODU4IDQuMTExIDEuODU4di4wMDFIOTkuODFjMy4zOTYgMCA2LjY2NS0yLjY0MyA3LjQ0My02LjAxNmwxOC41ODYtODAuNTA4Yy4zOTUtMS43MTEuMDU3LTMuMzk1LS45MjctNC42MTh6bS05OC41ODkgNzcuMTdjLTEuNzQzLTIuMzk3LTEuMzIzLTUuNjczLjk0LTcuMzE4bDM3LjM3OS0yNy4wNjd2LS41NTZMNDEuMTU3IDM2LjYwM2MtMS45MTYtMi4wMzgtMS43MTYtNS4zMzMuNDQ1LTcuMzYxIDIuMTYyLTIuMDI3IDUuNDY2LTIuMDE5IDcuMzgyLjAxOWwyOC4xOCAyOS45NzljMS42IDEuNzAyIDEuNzE4IDQuMjc5LjQ1NyA2LjI2NC0uMzg0Ljc3NC0xLjE4MiAxLjYyOC0yLjU5MyAyLjYxOGwtNDEuNDUgMjkuNzY5Yy0yLjI2MyAxLjY0NC01LjUxMiAxLjAzNC03LjI1NS0xLjM2M3ptNTkuNTQzLjUzOEg2My41MzJjLTIuNTk3IDAtNC43MDItMi4wODItNC43MDItNC42NXMyLjEwNS00LjY1IDQuNzAyLTQuNjVoMjIuMzMzYzIuNTk3IDAgNC43MDIgMi4wODIgNC43MDIgNC42NXMtMi4xMDQgNC42NS00LjcwMSA0LjY1eiIgY2xpcC1ydWxlPSJldmVub2RkIi8%2BPC9zdmc%2BCg%3D%3D" alt="PowerShell">
</p>

</div>

AI agents are getting direct access to production tools such as Kubernetes, Airflow, dbt, OpenMetadata and Spark. Without a single control point, each MCP server ends up with its own authentication, nobody can say which agent called what, and a compromised pod can call any backend directly.

This project puts **[agentgateway](https://agentgateway.dev)** in front of five MCP servers on a local Kubernetes cluster and builds the full trust chain **from configuration only, with no custom gateway code**:

| | |
|---|---|
| 🔐 **Authenticate** | Every call carries a Keycloak JWT; invalid tokens get `401` |
| 🧰 **Authorize per tool** | Each agent *sees* and *calls* only the tools its roles allow (deny by default) |
| 🪪 **Forward identity** | Backends learn who called; the caller's token never leaves the gateway |
| 🧱 **Isolate the network** | NetworkPolicy makes the gateway the only way into the backends |
| 📊 **Audit** | Every allow and deny is logged and charted in Grafana |

---

## Architecture

<p align="center">
  <img src="report/images/system-architecture.png" alt="System architecture: clients, agentgateway data plane with five checks, Keycloak, MCP backends and observability on kind" width="900">
</p>

Every tool call passes five checks in the gateway's data plane:

| # | Check | Question it answers | Configured in |
|:-:|---|---|---|
| 01 | **Check token** | Is the JWT genuine, unexpired and issued for `mcp-gateway`? | [`deploy/auth/`](deploy/auth/) |
| 02 | **Filter tools** | May these roles see and call this `{target}_{tool}`? | [`rbac/tool-access.yaml`](rbac/tool-access.yaml) |
| 03 | **Pass identity** | What does the backend learn? Headers set from verified claims; token dropped | [`deploy/auth/`](deploy/auth/) |
| 04 | **Swap token** | OpenMetadata gets an exchanged, audience-scoped token *(designed)* | [`deploy/identity/`](deploy/identity/) |
| 05 | **Log** | Who called which tool, and was it allowed? | [`observability/access-logs/`](observability/access-logs/) |

Network isolation sits underneath all five: [`deploy/network/`](deploy/network/) only lets the gateway namespace reach `mcp`.

<details>
<summary><b>Request sequence for a single tool call</b></summary>

```mermaid
sequenceDiagram
    autonumber
    participant A as AI agent
    participant K as Keycloak
    participant G as agentgateway
    participant B as Backend (e.g. radar)

    A->>K: client credentials (client_id, secret)
    K-->>A: access token (aud=mcp-gateway, roles=[...])
    A->>G: tools/call radar_list_namespaces + Bearer token
    G->>K: fetch JWKS (cached)
    G->>G: verify signature, issuer, audience
    G->>G: any rule matching roles + target + tool?
    alt no rule matches
        G-->>A: Unknown tool (hidden and denied)
    else allowed
        G->>B: list_namespaces + x-forwarded-user / x-agent-id (token removed)
        B-->>G: result
        G-->>A: result
    end
    G->>G: access log: agent, roles, target, tool, status
```

</details>

### Docker map

Everything runs on one Docker host: the kind node holds the gateway, Keycloak, mocks, radar and the observability stack; OpenMetadata and Spark History run as separate Compose projects on the same `kind` network.

<p align="center">
  <img src="report/images/docker-map.png" alt="Docker map of the kind node, OpenMetadata and Spark History compose projects with ports and volumes" width="900">
  <br><sub>Containers, exposed ports and volumes. Solid arrows: published ports; dashed arrows: traffic and storage.</sub>
</p>

---

## Tool catalog

One endpoint (`/mcp`) multiplexes five targets. Tools reach clients as `{target}_{tool}`, e.g. `radar_list_namespaces`.

| Target | Tools | Read | Write / Execute | Backend |
|---|:-:|:-:|:-:|---|
| `radar` | 4 | 3 | 1 | real (Helm) or mock |
| `spark-history` | 3 | 3 | – | real (Docker) or mock |
| `openmetadata` | 4 | 3 | 1 | real (Docker) or mock |
| `dbt` | 5 | 4 | 1 | mock |
| `airflow` | 5 | 3 | 2 | mock |
| **Total** | **21** | | | |

Mock write tools are write-*shaped* but have no side effects.

## AI agent identities

Each agent is its own confidential Keycloak client (OAuth client credentials). Roles are split by **capability per system** (viewer vs. operator/editor), not by job title, so an agent only gets what it needs.

| Agent | Roles | Tools |
|---|---|:-:|
| `cluster-observer-agent` | `kube_viewer` | 3 |
| `incident-response-agent` | `kube_operator`, `spark_viewer` | 7 |
| `spark-diagnostic-agent` | `spark_viewer` | 3 |
| `metadata-discovery-agent` | `metadata_viewer` | 3 |
| `metadata-steward-agent` | `metadata_editor` | 4 |
| `dbt-quality-agent` | `dbt_operator` | 5 |
| `airflow-monitor-agent` | `airflow_viewer` | 3 |
| `airflow-operator-agent` | `airflow_operator` | 5 |
| `platform-admin-agent` | `platform_admin` | 21 |
| `no-access-agent` | *(none)* | 0 |

The machine-readable contract is [`tests/expected/agent-tool-access.json`](tests/expected/agent-tool-access.json). Rules are OR-ed: an agent with several roles gets the union.

---

## Results

All numbers come from saved test output in [`evidence/`](evidence/).

| Check | Expected | Measured |
|---|:-:|:-:|
| Tools callable through `/mcp` with correct prefix | 21 | **21** |
| Agent × tool cells matching the contract in `tools/list` | 210 | **210** |
| Agents with the correct `roles` claim | 10 | **10** |
| Out-of-scope calls blocked | 9 | **9** |
| Calls with an audit record | 18 | **18** |
| Pod in `default` reaching a backend | blocked | **timeout** |
| *Warm start*: apply all layers (mean of 5) | – | **4.15 s** |
| *Warm start*: ready for agents (mean of 5) | – | **≈ 5.2 s** |

<p align="center">
  <img src="report/images/grafana-allow-deny.png" alt="Grafana allow/deny dashboard showing 9 allowed and 9 denied tool calls by user, role, target and tool" width="900">
  <br><sub>Grafana allow/deny dashboard after one RBAC test run: 9 allowed, 9 denied, broken down by agent, role, target and tool.</sub>
</p>

---

## Quick start

**Requirements:** `kind`, `kubectl`, `helm`, Docker with Compose (~8 GB memory), Node 22.19+, `curl`, `jq`; Python with `mcp==1.30.0` for the Python tests.

```bash
./bootstrap.sh     # once: kind cluster, Gateway API CRDs + agentgateway, mock image
./run.sh           # every time: apply all layers;  ./run.sh test  also runs the tests
```

On Windows, run the same steps through WSL with PowerShell:

```powershell
.\ops\up.ps1       # start everything
.\ops\down.ps1     # delete the cluster
```

Both paths are idempotent. The first run downloads about 4 GB. See **[QUICKSTART.md](QUICKSTART.md)** for the manual steps, checks, cleanup and troubleshooting.

| Service | Address |
|---|---|
| MCP endpoint | `http://localhost:8080/mcp` (with `Authorization: Bearer <token>`) |
| Keycloak | `http://localhost:8002` (`admin` / `admin`) |
| Grafana | `http://localhost:3000` (`admin` / `admin`) |
| OpenMetadata | `http://localhost:8585` |
| agentgateway admin UI (read-only) | `http://localhost:15000/ui/` |

> [!WARNING]
> The default credentials above and the test-user password `password` are for local use only. Change them before running anywhere else.

### Try it

```bash
TOKEN=$(scripts/get-token.sh engineer.user)
npx -y @modelcontextprotocol/inspector@0.21.2 --cli "http://localhost:8080/mcp" \
  --transport http --header "Authorization: Bearer $TOKEN" --method tools/list
```

Always call the gateway, never a backend directly.

### Tests

```bash
node tests/static_contract_test.mjs   # manifests vs. contract, no cluster needed
python servers/smoke_test.py          # mocks locally, identity headers
python tests/gateway_smoke.py         # all 21 tools through localhost:8080
python tests/agent_rbac_smoke.py      # 10 agents: claims, visible tools, allowed/denied calls
bash scripts/run-tests.sh             # everything against the running cluster
```

---

## Repository layout

```
deploy/
  agentgateway/      Gateway, HTTPRoute, AgentgatewayBackend (5 targets)
  auth/              JWT validation + identity headers
  identity/          token exchange (OpenMetadata)
  keycloak/          Keycloak, realm and agent setup scripts
  network/           NetworkPolicy: backends accept only the gateway
  real-servers/      real radar (Helm), OpenMetadata and Spark History (Docker)
  cluster/           kind config and CNI notes
rbac/                tool-access.yaml: the role → tool policy (source of truth)
servers/             FastMCP mocks, one folder per target; k8s/mocks.yaml deploys them
observability/       access-log fields, Loki/Alloy/Grafana dashboard
tests/               contract, smoke and RBAC tests; expected/ holds the matrices
scripts/  ops/       Linux (bash) and Windows (PowerShell) automation
evidence/            saved outputs behind every reported number
docs/                design notes, observability review, diagrams/
report/              internship report (LaTeX)
```

### Common changes

| I want to… | Change |
|---|---|
| Give a role more tools | `rbac/tool-access.yaml` **and** `tests/expected/` in the same commit |
| Add an agent | New Keycloak client + roles, then add it to `tests/expected/agent-tool-access.json` |
| Swap a mock for a real server | `host`/`port` of the target in `deploy/agentgateway/AgentgatewayBackend.yaml`; name and rules stay |
| Add or rename a tool | `servers/<target>/server.py`, backend, RBAC, expected matrix, `CASES` in `tests/gateway_smoke.py`, and the 21-tool count |

Keep a target's name identical across its mock folder, Service, backend target, RBAC rules and tests.

---

## Scope and limitations

This is a proof of concept on a local kind cluster, not a production deployment.

- Token exchange for OpenMetadata and per-resource authorization on real backends are **designed but not complete**.
- Agents acting **on behalf of a human user** (delegated identity) is out of scope.
- Only *warm start* was measured; *cold start* and gateway latency under load were not.

## Documentation

| Document | Content |
|---|---|
| [QUICKSTART.md](QUICKSTART.md) | Setup, checks, cleanup, troubleshooting |
| [docs/ai-agent-tool-access.md](docs/ai-agent-tool-access.md) | Agent identities, capability roles, 21-tool matrix |
| [rbac/policy-overlap-experiment.md](rbac/policy-overlap-experiment.md) | Why everything is one `Allow` policy |
| [docs/agentgateway-observability-review.md](docs/agentgateway-observability-review.md) | Logs, metrics, traces and denials on agentgateway v1.5.0 |
| [deploy/real-servers/README.md](deploy/real-servers/README.md) | Real radar, OpenMetadata and Spark History, and their limits |
| [docs/diagrams/](docs/diagrams/) | Editable draw.io diagrams and the numbered system flow |

## Authors

Internship project at VietCredit, Faculty of Information Systems, University of Economics and Law (VNU-HCM), 2026.

- **Vòng Hữu Quân**: mock MCP servers, Keycloak realm, JWT and RBAC rules, Linux automation, documentation
- **Nguyễn Trần Thái Huy**: AI agent identities, NetworkPolicy, observability and Grafana, Windows automation, testing and evaluation

Supervisor: Assoc. Prof. Dr. Lê Hoành Sử.
