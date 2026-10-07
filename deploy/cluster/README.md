# deploy/cluster

**What:** the local Kubernetes cluster the whole project runs on (`kind`), plus the CNI choice.

**Contains (planned):**
- `kind-config.yaml`: cluster definition. Use Calico if kind's default CNI does not enforce NetworkPolicy.

**README mapping:** *Folder structure* → `deploy/cluster/`. Build step 1 (*Install*), guideline §1 and §6.

**Why it matters:** without a CNI that enforces NetworkPolicy, `deploy/network/` does nothing and identity headers can be forged by any pod.

**Check:** `kubectl get nodes` is Ready; a NetworkPolicy test blocks a pod (guideline §6).
