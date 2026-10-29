#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
kubectl_bin=${KUBECTL_BIN:-kubectl}

command -v "$kubectl_bin" >/dev/null

if ! "$kubectl_bin" get crd agentgatewaypolicies.agentgateway.dev >/dev/null 2>&1; then
  echo "agentgateway CRDs are not installed. Install the pinned chart before running this script." >&2
  exit 1
fi

"$repo_dir/scripts/bootstrap-agent-secrets.sh"

"$kubectl_bin" apply -f "$repo_dir/deploy/keycloak/realm-config.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/keycloak/keycloak.yaml"
"$kubectl_bin" -n keycloak rollout status deployment/keycloak --timeout=180s

"$kubectl_bin" apply -f "$repo_dir/servers/k8s/mocks.yaml"
"$kubectl_bin" -n mcp rollout status deployment/radar --timeout=120s
"$kubectl_bin" -n mcp rollout status deployment/spark-history --timeout=120s
"$kubectl_bin" -n mcp rollout status deployment/openmetadata --timeout=120s
"$kubectl_bin" -n mcp rollout status deployment/dbt --timeout=120s
"$kubectl_bin" -n mcp rollout status deployment/airflow --timeout=120s

"$kubectl_bin" apply -f "$repo_dir/deploy/agentgateway/Gateway.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/agentgateway/AgentgatewayBackend.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/agentgateway/HTTPRoute.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/auth/keycloak-reference-grant.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/auth/jwt.yaml"
"$kubectl_bin" apply -f "$repo_dir/rbac/tool-access.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/identity/kubernetes-rbac.yaml"
"$kubectl_bin" apply -f "$repo_dir/deploy/network/backends.yaml"
"$kubectl_bin" apply -f "$repo_dir/observability/access-logs/policy.yaml"

echo "Applied AI Agent authentication, tool RBAC, backend RBAC, network and audit policies."
echo "Verify every AgentgatewayPolicy reports Accepted=True before testing."
