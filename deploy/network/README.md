# deploy/network

**What:** the network boundary that makes the gateway the only way into the backends.

**Contains (planned):**
- `backends.yaml`: a `NetworkPolicy` in namespace `mcp` allowing ingress only from namespace `agentgateway-system`.

**README mapping:** *Network* checkpoint. Build step 6, guideline §6.

**Why it matters:** identity headers are trustworthy only because nothing else can reach a backend. Without this policy any pod can forge them.

**Depends on:** a CNI that enforces NetworkPolicy (`deploy/cluster/`).

**Check:** a pod outside the gateway cannot connect to a backend Service.
