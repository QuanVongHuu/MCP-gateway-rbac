#!/usr/bin/env bash
# Builds the test realm `mcp` (guideline §3). Dev only: test users' passwords are the part of the
# username before the dot (multi.user / multi).
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash on Windows rewrites /opt/... paths without this

ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
REALM=mcp

kc() { kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@"; }

kc config credentials --server http://localhost:8080 --realm master \
  --user "$ADMIN_USER" --password "$ADMIN_PASSWORD"

if kc get "realms/$REALM" >/dev/null 2>&1; then
  echo "realm $REALM already exists; delete it first to rebuild: kcadm.sh delete realms/$REALM"
  exit 0
fi

kc create realms -s realm=$REALM -s enabled=true

# mcp-gateway: the audience, and the owner of the gateway roles. Its generated secret stays in Keycloak.
GW=$(kc create clients -r $REALM -i -s clientId=mcp-gateway -s publicClient=false \
  -s standardFlowEnabled=false -s 'attributes."standard.token.exchange.enabled"=true' | tr -d '\r')
for role in data_admin data_engineer bi_engineer analyst; do
  kc create "clients/$GW/roles" -r $REALM -s name=$role
done

# openmetadata: the audience for exchanged tokens (§5)
kc create clients -r $REALM -s clientId=openmetadata -s publicClient=false -s standardFlowEnabled=false
# without this scope the exchange fails with "Requested audience not available: openmetadata"
SCOPE=$(kc create client-scopes -r $REALM -i -s name=openmetadata-audience -s protocol=openid-connect | tr -d '\r')
kc create "client-scopes/$SCOPE/protocol-mappers/models" -r $REALM -s name=aud-openmetadata \
  -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=openmetadata' -s 'config."access.token.claim"=true'
kc update "clients/$GW/default-client-scopes/$SCOPE" -r $REALM

# mcp-cli: public, password grant, test users only
CLI=$(kc create clients -r $REALM -i -s clientId=mcp-cli -s publicClient=true \
  -s directAccessGrantsEnabled=true -s standardFlowEnabled=false | tr -d '\r')
kc create "clients/$CLI/protocol-mappers/models" -r $REALM -s name=aud-mcp-gateway \
  -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=mcp-gateway' -s 'config."access.token.claim"=true'
kc create "clients/$CLI/protocol-mappers/models" -r $REALM -s name=roles \
  -s protocol=openid-connect -s protocolMapper=oidc-usermodel-client-role-mapper \
  -s 'config."usermodel.clientRoleMapping.clientId"=mcp-gateway' -s 'config."claim.name"=roles' \
  -s 'config."multivalued"=true' -s 'config."jsonType.label"=String' -s 'config."access.token.claim"=true'

# groups stand in for company directory groups
declare -A GROUP_ID
for pair in data-team:data_engineer bi-team:bi_engineer; do
  group=${pair%%:*}
  GROUP_ID[$group]=$(kc create groups -r $REALM -i -s name=$group | tr -d '\r')
  kc add-roles -r $REALM --gname $group --cclientid mcp-gateway --rolename ${pair##*:}
done

# user:direct-role:groups (comma separated)
for spec in analyst.user:analyst: engineer.user::data-team multi.user::data-team,bi-team \
            admin.user:data_admin: nobody.user::; do
  IFS=: read -r user role groups <<<"$spec"
  # Keycloak 26 refuses the password grant ("Account is not fully set up") without name and email
  USER_ID=$(kc create users -r $REALM -i -s username=$user -s enabled=true -s emailVerified=true \
    -s email=$user@example.com -s firstName=${user%%.*} -s lastName=user | tr -d '\r')
  kc set-password -r $REALM --username $user --new-password "${user%%.*}"
  if [ -n "$role" ]; then
    kc add-roles -r $REALM --uusername $user --cclientid mcp-gateway --rolename $role
  fi
  for group in ${groups//,/ }; do
    kc update "users/$USER_ID/groups/${GROUP_ID[$group]}" -r $REALM -n \
      -s realm=$REALM -s userId=$USER_ID -s groupId=${GROUP_ID[$group]}
  done
done

echo "realm $REALM ready"
