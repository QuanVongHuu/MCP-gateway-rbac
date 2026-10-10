# deploy/real-servers

**What:** the real MCP servers that replace three of the mocks behind the same gateway targets (guideline §9). The target names, `rbac/tool-access.yaml` and the tests are unchanged; only `host` and `port` of each target in `deploy/agentgateway/AgentgatewayBackend.yaml` differ.

| Target | Real server | Runs in | Reached at | Caller identity |
|---|---|---|---|---|
| `radar` | skyhook-io/radar 1.16.0, proxy mode | kind, namespace `mcp` (Helm release `radar-real`) | `radar-real.mcp.svc.cluster.local:9280` | identity headers; radar impersonates the user, Kubernetes RBAC decides |
| `openmetadata` | OpenMetadata 1.13.3 | Docker (`openmetadata/`) | `openmetadata-real:8585` | exchanged token; OpenMetadata applies its own permissions |
| `spark-history` | kubeflow Spark History Server MCP 1.0.1 | Docker (`spark-history/`) | `spark-history-real:18888` | none; it cannot receive the caller |

`dbt` and `airflow` are still mocks.

**Start:**

```bash
kubectl apply -f radar/rbac.yaml
helm repo add skyhook https://skyhook-io.github.io/helm-charts
helm upgrade -i radar-real skyhook/radar --version 1.16.0 -n mcp -f radar/values.yaml

bash openmetadata/up.sh        # first run pulls about 3 GB; wait for http://localhost:8585
bash openmetadata/setup.sh     # test users and one sample table
bash spark-history/up.sh

kubectl apply -f ../agentgateway/AgentgatewayBackend.yaml
```

**Back to a mock:** set the target's `host` and `port` back to the values in the comment beside it and apply the backend again.

**Know before you rely on it:**
- **One target down breaks everyone.** The gateway initializes every target, so if a container here is stopped, `initialize` fails for all callers. Start these before using the gateway, or point the target back at its mock.
- **The Docker containers are outside the NetworkPolicy of §6.** They are reachable from anything on Docker's `kind` network, including every pod. OpenMetadata validates each token itself. Spark History Server MCP has no authentication at all: use sample or non-sensitive event logs only.
- **OpenMetadata does not check the token's audience.** It accepts any valid token of realm `mcp`, including a caller's original gateway token sent to it directly. The token exchange still limits what the gateway hands over, but the audience is not enforced on OpenMetadata's side.
- **A user must exist in OpenMetadata** before their token is accepted (`setup.sh`). Unknown users get 404.
- **`data_admin` is bound to Kubernetes `edit` cluster-wide**, which can read Secrets, including `mcp-gateway-client-secret` in namespace `mcp`. Narrow `radar/rbac.yaml` before using this beyond a lab.
