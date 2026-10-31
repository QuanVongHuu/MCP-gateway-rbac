#!/usr/bin/env bash
# Applies the layers in build order (README "How to leverage it"; guideline §2 to §7). Safe to re-run.
#
# Expects the kind cluster, the Gateway API CRDs, the agentgateway Helm charts and the mock image
# (README "Quick start"). It does not start the real servers: AgentgatewayBackend.yaml points radar,
# openmetadata and spark-history at them, and the gateway fails for every caller while one target
# is down. ./run.sh at the repo root runs this script and starts them.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash on Windows rewrites /opt/... paths without this
cd "$(dirname "$0")/.."

step() { echo; echo "== $1"; }

step "2. gateway, mock backends, route"
kubectl apply -f deploy/agentgateway/Gateway.yaml
kubectl apply -f servers/k8s/mocks.yaml
kubectl apply -f deploy/agentgateway/AgentgatewayBackend.yaml -f deploy/agentgateway/HTTPRoute.yaml

step "3. Keycloak and realm mcp"
kubectl apply -f deploy/keycloak/keycloak.yaml
kubectl rollout status deploy/keycloak -n keycloak --timeout=300s
# rollout status returns before Keycloak answers: the Deployment has no readiness probe
until kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 --realm master --user admin --password admin >/dev/null 2>&1; do
  sleep 5
done
# setup-realm.sh deletes and rebuilds the realm, so only run it when the realm is missing
if kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh get realms/mcp >/dev/null 2>&1; then
  echo "realm mcp exists, keeping it (rebuild: bash deploy/keycloak/setup-realm.sh, then this script)"
else
  bash deploy/keycloak/setup-realm.sh
fi

step "3b. AI Agent service-account clients"
bash scripts/bootstrap-agent-secrets.sh
bash deploy/keycloak/setup-agents.sh

step "4-5. authentication, caller identity, token exchange"
# the gateway's client secret for token exchange, copied from Keycloak so it follows a rebuilt realm
kc() { kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@"; }
client=$(kc get clients -r mcp -q clientId=mcp-gateway --fields id --format csv --noquotes | tr -d '\r')
secret=$(kc get clients/"$client"/client-secret -r mcp --fields value --format csv --noquotes | tr -d '\r')
kubectl create secret generic mcp-gateway-client-secret -n mcp --from-literal=clientSecret="$secret" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f deploy/auth/jwt.yaml -f deploy/identity/openmetadata.yaml

step "4. tool access"
kubectl apply -f rbac/tool-access.yaml
kubectl apply -f deploy/identity/kubernetes-rbac.yaml

step "6. network"
kubectl apply -f deploy/network/backends.yaml

step "7. access logs"
kubectl apply -f observability/access-logs/policy.yaml

echo
kubectl get agentgatewaypolicy -A
echo
echo "Layers applied."
