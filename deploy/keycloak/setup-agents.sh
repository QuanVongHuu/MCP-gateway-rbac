#!/usr/bin/env bash
# Adds the AI Agent service-account clients and capability roles to the realm `mcp` built by
# setup-realm.sh, so human users (password login) and agents (client credentials) share one realm.
# Source of truth: realm-config.yaml (clients, roles, role grants). Secrets come from the Kubernetes
# Secret agent-client-secrets (scripts/bootstrap-agent-secrets.sh) and are never printed.
# Safe to re-run: clients are overwritten with the same secrets and role grants re-applied.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/../.."

REALM=mcp
kc() { kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@"; }

# realm JSON embedded in the ConfigMap (same extraction as tests/static_contract_test.mjs)
json=$(sed -n '/mcp-realm.json: |/,$p' deploy/keycloak/realm-config.yaml | tail -n +2 | sed 's/^    //')

# replace each ${..._SECRET} placeholder with the real secret
for cid in $(jq -r '.clients[] | select(.secret) | .clientId' <<<"$json" | tr -d '\r'); do
  sec=$(kubectl -n keycloak get secret agent-client-secrets -o "jsonpath={.data.$cid}" | base64 -d)
  [ -n "$sec" ] || { echo "setup-agents: no secret for $cid (run scripts/bootstrap-agent-secrets.sh)" >&2; exit 1; }
  json=$(jq --arg c "$cid" --arg s "$sec" '(.clients[] | select(.clientId == $c)).secret = $s' <<<"$json")
done

kc config credentials --server http://localhost:8080 --realm master --user admin --password admin >/dev/null

# mcp-gateway is owned by setup-realm.sh (token exchange); import only the agent clients and roles
jq '{ifResourceExists: "OVERWRITE",
     clients: [.clients[] | select(.clientId != "mcp-gateway")],
     roles: {client: {"mcp-gateway": .roles.client["mcp-gateway"]}}}' <<<"$json" \
  | kubectl exec -i -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh create partialImport -r $REALM -f - >/dev/null

# overwriting a client recreates its service-account user, so grant the roles every time
jq -r '.users[] | [.serviceAccountClientId] + (.clientRoles["mcp-gateway"] // []) | join(" ")' <<<"$json" | tr -d '\r' |
while read -r cid roles; do
  # the username search can miss a just-recreated service-account user, so resolve it through the client
  client_uuid=$(kc get clients -r $REALM -q clientId="$cid" --fields id --format csv --noquotes | tr -d '\r')
  user_id=$(kc get clients/"$client_uuid"/service-account-user -r $REALM --fields id --format csv --noquotes | tr -d '\r')
  for role in $roles; do
    kc add-roles -r $REALM --uid "$user_id" --cclientid mcp-gateway --rolename "$role"
  done
done
echo "agents: $(jq '[.clients[] | select(.secret)] | length' <<<"$json") service-account clients in realm $REALM"
