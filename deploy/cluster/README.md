# deploy/cluster

**What:** the local Kubernetes cluster the whole project runs on (`kind`), plus the CNI choice.

**Contains:**
- `kind-config.yaml`: single-node cluster `mcp` with the default CNI disabled and pod CIDR `192.168.0.0/16`. Install Calico before deploying workloads so NetworkPolicy is enforced.

**README mapping:** *Folder structure* → `deploy/cluster/`. Build step 1 (*Install*), guideline §1 and §6.

**Why it matters:** without a CNI that enforces NetworkPolicy, `deploy/network/` does nothing and identity headers can be forged by any pod.

**Check:** `kubectl get nodes` is Ready; a NetworkPolicy test blocks a pod (guideline §6).
