#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
kubectl_bin=${KUBECTL_BIN:-kubectl}

command -v "$kubectl_bin" >/dev/null
command -v openssl >/dev/null

"$kubectl_bin" apply -f "$repo_dir/deploy/keycloak/namespace.yaml"

bootstrap_exists=false
agents_exist=false
"$kubectl_bin" -n keycloak get secret keycloak-bootstrap >/dev/null 2>&1 && bootstrap_exists=true
"$kubectl_bin" -n keycloak get secret agent-client-secrets >/dev/null 2>&1 && agents_exist=true

if [[ "$bootstrap_exists" == true || "$agents_exist" == true ]]; then
  if [[ "$bootstrap_exists" == true && "$agents_exist" == true ]]; then
    if [[ "${ROTATE_AGENT_SECRETS:-false}" != "true" ]]; then
      echo "Keycloak and agent secrets already exist; leaving them unchanged."
      exit 0
    fi
    echo "Rotating Keycloak and agent secrets because ROTATE_AGENT_SECRETS=true."
  else
    echo "Refusing partial rotation: one expected Secret exists and the other does not." >&2
    exit 1
  fi
fi

secret_dir=$(mktemp -d)
cleanup() {
  find "$secret_dir" -type f -exec shred -u {} + 2>/dev/null || true
  rmdir "$secret_dir" 2>/dev/null || true
}
trap cleanup EXIT
umask 077

printf '%s' "${KEYCLOAK_ADMIN_USERNAME:-admin}" >"$secret_dir/username"
openssl rand -hex 32 | tr -d '\n' >"$secret_dir/password"

agent_clients=(
  cluster-observer-agent
  incident-response-agent
  spark-diagnostic-agent
  metadata-discovery-agent
  metadata-steward-agent
  dbt-quality-agent
  airflow-monitor-agent
  airflow-operator-agent
  platform-admin-agent
  no-access-agent
)

for client_id in "${agent_clients[@]}"; do
  openssl rand -hex 32 | tr -d '\n' >"$secret_dir/$client_id"
done

"$kubectl_bin" -n keycloak create secret generic keycloak-bootstrap \
  --from-file=username="$secret_dir/username" \
  --from-file=password="$secret_dir/password" \
  --dry-run=client -o yaml | "$kubectl_bin" apply -f -

agent_secret_args=()
for client_id in "${agent_clients[@]}"; do
  agent_secret_args+=("--from-file=$client_id=$secret_dir/$client_id")
done
"$kubectl_bin" -n keycloak create secret generic agent-client-secrets \
  "${agent_secret_args[@]}" --dry-run=client -o yaml | "$kubectl_bin" apply -f -

echo "Created Keycloak bootstrap and per-agent client secrets without printing their values."
