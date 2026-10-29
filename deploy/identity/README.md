# deploy/identity

**What:** per-backend identity for backends that need a real token instead of headers. Today that is OpenMetadata.

**Contains:**
- `kubernetes-rbac.yaml`: maps verified Radar proxy groups to cluster namespace-read and namespace-scoped workload read/operator permissions. Write bindings are intentionally not cluster-wide.

**Still planned:**
- `openmetadata.yaml`: OAuth token exchange at Keycloak so the real backend receives a token whose audience is only `openmetadata`.

**README mapping:** the token-exchange half of the *Identity* checkpoint. Build step 5, guideline §5.

**Open question:** the policy field path and whether it can target one MCP target are marked *check* in the guideline. If it only works on a whole `AgentgatewayBackend`, OpenMetadata needs its own backend and route.

**Check:** the exchange works against Keycloak directly with `curl` first, then through the gateway.
