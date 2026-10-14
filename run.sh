#!/usr/bin/env bash
# Brings the whole system up with one command, on an existing kind cluster. Safe to re-run.
#
#   ./run.sh         start everything and wait until the gateway answers
#   ./run.sh test    the same, then run scripts/run-tests.sh
#
# Do README "Quick start" steps 1 to 3 once before the first run: the kind cluster `gatewayapi`,
# the Gateway API CRDs and agentgateway Helm charts, and the mock image.
#
# What it starts: the Kubernetes layers (scripts/up.sh), the real radar (Helm), the real
# OpenMetadata and Spark History Server MCP (Docker Compose), and two port-forwards in the
# background: the gateway on localhost:8080 and Keycloak on localhost:8002.
set -euo pipefail
cd "$(dirname "$0")"

step() { echo; echo "==== $1"; }
die() { echo "run.sh: $1" >&2; exit 1; }

http_code() { curl -s -m 5 -o /dev/null -w '%{http_code}' "$@"; }

# wait_for <what> <timeout seconds> <command...>
wait_for() {
  local what=$1 deadline=$((SECONDS + $2)); shift 2
  echo "waiting for $what ..."
  until "$@" >/dev/null 2>&1; do
    [ "$SECONDS" -lt "$deadline" ] || die "timed out waiting for $what"
    sleep 5
  done
}

# forward <local port> <namespace> <resource> <remote port>: skipped when the port already answers
forward() {
  if [ "$(http_code "http://localhost:$1/")" != 000 ]; then
    echo "localhost:$1 already answers, keeping it"
  else
    nohup kubectl port-forward -n "$2" "$3" "$1:$4" >/dev/null 2>&1 &
    echo "port-forward localhost:$1 -> $2 $3:$4 (background, pid $!)"
  fi
}

openmetadata_ready() { [ "$(http_code http://localhost:8585/api/v1/system/version)" = 200 ]; }

gateway_ready() {
  local token
  token=$(scripts/get-token.sh engineer.user 2>/dev/null) || return 1
  [ "$(http_code http://localhost:8080/mcp -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
      -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"run.sh","version":"1"}}}')" = 200 ]
}

step "0. Preflight"
for tool in kubectl helm docker curl jq; do
  command -v "$tool" >/dev/null || die "$tool is not installed (README: Requirements)"
done
docker info >/dev/null 2>&1 || die "Docker is not running"
# the cluster name is fixed: the OpenMetadata container reaches Keycloak at gatewayapi-control-plane
[ "$(kubectl config current-context)" = kind-gatewayapi ] \
  || die "kubectl context is not kind-gatewayapi (README Quick start step 1, or: kubectl config use-context kind-gatewayapi)"
kubectl get nodes >/dev/null 2>&1 || die "the cluster does not answer (is Docker running?)"
kubectl get crd agentgatewaypolicies.agentgateway.dev >/dev/null 2>&1 \
  || die "agentgateway is not installed (README Quick start step 2)"
docker exec gatewayapi-control-plane crictl images 2>/dev/null | grep -q mcp-mocks \
  || die "the mock image is not in the cluster (README Quick start step 3)"
echo "ok"

step "1. Kubernetes layers: gateway, mocks, Keycloak, policies"
bash scripts/up.sh

step "2. Real radar (Helm, namespace mcp)"
kubectl apply -f deploy/real-servers/radar/rbac.yaml
helm repo add skyhook https://skyhook-io.github.io/helm-charts >/dev/null 2>&1 || true
helm upgrade -i radar-real skyhook/radar --version 1.16.0 -n mcp \
  -f deploy/real-servers/radar/values.yaml --wait --timeout 5m | grep -E "STATUS|REVISION"

step "3. Real OpenMetadata and Spark History Server MCP (Docker; the first run pulls about 4 GB)"
bash deploy/real-servers/openmetadata/up.sh
bash deploy/real-servers/spark-history/up.sh

step "4. Port-forwards"
kubectl rollout status deploy/agentgateway-proxy -n agentgateway-system --timeout=300s
forward 8080 agentgateway-system deployment/agentgateway-proxy 80
forward 8002 keycloak svc/keycloak 80
wait_for "Keycloak on localhost:8002" 120 scripts/get-token.sh admin.user

step "5. OpenMetadata content: test users and a sample table"
wait_for "OpenMetadata on localhost:8585" 600 openmetadata_ready
bash deploy/real-servers/openmetadata/setup.sh

step "6. Gateway"
# after a realm rebuild the gateway may reject tokens until its key cache (5 minutes) refreshes
wait_for "the gateway to accept a token and reach every target" 600 gateway_ready

cat <<'EOF'

The system is up.

  MCP endpoint    http://localhost:8080/mcp        send "Authorization: Bearer <token>"
  A token         TOKEN=$(scripts/get-token.sh engineer.user)
  Keycloak        http://localhost:8002            admin / admin
  OpenMetadata    http://localhost:8585
  Admin UI        kubectl port-forward -n agentgateway-system deployment/agentgateway-proxy 15000
                  then http://localhost:15000/ui/  (read-only, debugging; not started by run.sh)
  Tests           bash scripts/run-tests.sh        or: ./run.sh test

The two port-forwards keep running in the background; a reboot or a Docker restart ends them,
and ./run.sh starts them again.
EOF

if [ "${1:-}" = test ]; then
  step "7. Tests"
  exec bash scripts/run-tests.sh
fi
