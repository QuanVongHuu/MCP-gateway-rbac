#!/usr/bin/env bash
# One-time setup (QUICKSTART.md step 2). Safe to re-run.
# Creates the kind cluster `gatewayapi`, installs Gateway API CRDs and agentgateway,
# then builds the mock image and loads it into the cluster. Run ./run.sh afterwards.
set -euo pipefail
cd "$(dirname "$0")"

step() { echo; echo "==== $1"; }
die() { echo "bootstrap.sh: $1" >&2; exit 1; }

for tool in kind kubectl helm docker; do
  command -v "$tool" >/dev/null || die "$tool is not installed (README: Requirements)"
done
docker info >/dev/null 2>&1 || die "Docker is not running"

step "1. kind cluster gatewayapi"
if kind get clusters 2>/dev/null | grep -qx gatewayapi; then
  echo "cluster gatewayapi already exists"
else
  kind create cluster --name gatewayapi
fi
kubectl config use-context kind-gatewayapi

step "2. Gateway API CRDs and agentgateway (v1.5.0)"
kubectl apply --server-side --force-conflicts \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.0/standard-install.yaml
helm upgrade -i agentgateway-crds oci://cr.agentgateway.dev/charts/agentgateway-crds \
  --create-namespace --namespace agentgateway-system --version v1.5.0
helm upgrade -i agentgateway oci://cr.agentgateway.dev/charts/agentgateway \
  --namespace agentgateway-system --version v1.5.0 --wait

step "3. Mock image"
docker build -t mcp-mocks:dev servers
kind load docker-image mcp-mocks:dev --name gatewayapi

echo
echo "bootstrap done. Next: ./run.sh"
