# Quick start

From an empty machine to a working MCP gateway with role-based tool access. For what the system is and how it works, see [README.md](README.md).

## 1. Install the tools

| Tool | Used for |
|---|---|
| Docker (with Compose), about 8 GB of memory | the kind node, OpenMetadata, Spark History Server MCP |
| `kind` | the local Kubernetes cluster |
| `kubectl`, `helm` | everything inside the cluster |
| `curl`, `jq` | tokens and health checks |
| Node 22.19+ | MCP Inspector (the tests) |

Install them in one go:

```bash
# Windows (PowerShell); also install Git for Windows if you have no Git Bash yet: Git.Git
winget install Docker.DockerDesktop Kubernetes.kind Kubernetes.kubectl Helm.Helm jqlang.jq OpenJS.NodeJS.LTS

# macOS (Homebrew)
brew install kind kubectl helm jq node
brew install --cask docker
```

`curl` already ships with Windows 10+ and macOS. Then start Docker Desktop, give it about 8 GB of memory (macOS: Settings → Resources; Windows with WSL 2: `memory=8GB` under `[wsl2]` in `%UserProfile%\.wslconfig`), and open a new terminal so the new tools are on `PATH`.

On Windows, run every command below in **Git Bash**, not PowerShell or cmd.

## 2. One-time setup

```bash
./bootstrap.sh
```

It does three things and skips what already exists, so it is safe to re-run:

1. creates the kind cluster `gatewayapi` and switches `kubectl` to `kind-gatewayapi`,
2. installs the Gateway API CRDs (v1.6.0) and agentgateway (Helm charts v1.5.0),
3. builds the mock image `mcp-mocks:dev` and loads it into the cluster.

The cluster name must stay `gatewayapi`: the OpenMetadata container reaches Keycloak through the node `gatewayapi-control-plane`.

Run `./bootstrap.sh` again after changing anything in `servers/`, to rebuild and reload the mock image.

<details>
<summary>The same steps by hand</summary>

```bash
kind create cluster --name gatewayapi

kubectl apply --server-side --force-conflicts \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.0/standard-install.yaml
helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds \
  --create-namespace --namespace agentgateway-system --version v1.5.0
helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway \
  --namespace agentgateway-system --version v1.5.0 --wait

docker build -t mcp-mocks:dev servers
kind load docker-image mcp-mocks:dev --name gatewayapi
```

</details>

## 3. Start everything

```bash
./run.sh          # or: ./run.sh test   to run the tests at the end
```

`run.sh` checks the one-time setup first and names the missing step. Then it applies the Kubernetes layers (gateway, mocks, Keycloak, policies), installs the real radar, starts OpenMetadata and Spark History Server MCP in Docker, installs the Grafana stack, starts port-forwards in the background and waits until the gateway answers.

The first run downloads about 4 GB and takes several minutes. Later runs only restart what is missing. This is also the command to bring the system back after a reboot or a Docker restart.

## 4. Check it works

When `run.sh` prints `The system is up.`:

| What | Where |
|---|---|
| MCP endpoint | `http://localhost:8080/mcp`, with `Authorization: Bearer <token>` |
| A token | `TOKEN=$(scripts/get-token.sh engineer.user)` |
| Keycloak admin console | `http://localhost:8002`, `admin` / `admin` |
| OpenMetadata | `http://localhost:8585` |
| Grafana allow/deny dashboard | `http://localhost:3000`, `admin` / `admin` |
| Admin UI (read-only) | `kubectl port-forward -n agentgateway-system deployment/agentgateway-proxy 15000`, then `http://localhost:15000/ui/` |

List the tools one user may call:

```bash
TOKEN=$(scripts/get-token.sh engineer.user)
npx -y @modelcontextprotocol/inspector@0.21.2 --cli "http://localhost:8080/mcp" --transport http \
  --header "Authorization: Bearer $TOKEN" --method tools/list
```

Try another user (`analyst.user`, `multi.user`, `admin.user`, `nobody.user`; password `password`) and the list changes. Run the whole test suite with:

```bash
bash scripts/run-tests.sh
```

It exits 0 only when every check passes.

## 5. Stop and clean up

```bash
docker compose -p openmetadata-real down      # add -v to delete its data too
docker compose -p spark-history-real down
kind delete cluster --name gatewayapi         # or in PowerShell: ops/down.ps1
```

Stopping only the Docker containers breaks the gateway for every caller, because it connects to every target when a session starts. Start them again with `./run.sh`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `kubectl context is not kind-gatewayapi` | `kubectl config use-context kind-gatewayapi`, or run `./bootstrap.sh` |
| `agentgateway is not installed` or `the mock image is not in the cluster` | run `./bootstrap.sh` |
| `the cluster does not answer` | start Docker Desktop and wait until `kubectl get nodes` shows `Ready` |
| `get-token: no token ...` | the Keycloak port-forward on 8002 has stopped; run `./run.sh` again |
| The gateway rejects valid tokens right after Keycloak was rebuilt | its key cache refreshes within 5 minutes; wait, or re-run `./run.sh` |
| Every call fails at `initialize` | one target is down, usually an OpenMetadata or Spark container; run `./run.sh` again |
| A port (8080, 8002, 3000) is taken by another program | `run.sh` keeps whatever already answers there; stop that program first |
