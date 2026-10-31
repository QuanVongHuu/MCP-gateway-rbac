#!/usr/bin/env bash
# Builds the test realm `mcp` (guideline §3). Dev only: every test user gets TEST_USER_PASSWORD
# (default `password`); scripts/get-token.sh uses the same variable.
# Re-running deletes and rebuilds the realm: new signing keys and a new mcp-gateway client secret.
# Run scripts/up.sh afterwards to copy the secret to the gateway; old tokens stop working.
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash on Windows rewrites /opt/... paths without this

ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
REALM=mcp

kc() { kubectl exec -n keycloak deploy/keycloak -- /opt/keycloak/bin/kcadm.sh "$@"; }

kc config credentials --server http://localhost:8080 --realm master \
  --user "$ADMIN_USER" --password "$ADMIN_PASSWORD"

# 1. Realm (delete first so the script can be re-run)
kc delete realms/$REALM 2>/dev/null || true
kc create realms -s realm=$REALM -s enabled=true

# 2. mcp-gateway: confidential, standard token exchange on
GW=$(kc create clients -r $REALM -i \
  -s clientId=mcp-gateway \
  -s publicClient=false \
  -s serviceAccountsEnabled=true \
  -s 'attributes."standard.token.exchange.enabled"=true')

# four client roles
for role in data_admin data_engineer bi_engineer analyst; do
  kc create "clients/$GW/roles" -r $REALM -s name=$role
done

# 3. openmetadata: only exists so exchanged tokens can be addressed to it
kc create clients -r $REALM -s clientId=openmetadata -s publicClient=false

# 3b. Make the openmetadata audience available to mcp-gateway. Without this scope the token
# exchange fails with "Requested audience not available: openmetadata".
SCOPE=$(kc create client-scopes -r $REALM -i -s name=openmetadata-audience -s protocol=openid-connect)
kc create "client-scopes/$SCOPE/protocol-mappers/models" -r $REALM \
  -s name=audience-openmetadata \
  -s protocol=openid-connect \
  -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=openmetadata' \
  -s 'config."access.token.claim"=true'
kc update "clients/$GW/default-client-scopes/$SCOPE" -r $REALM

# 4. mcp-cli: public client for test logins
CLI=$(kc create clients -r $REALM -i \
  -s clientId=mcp-cli \
  -s publicClient=true \
  -s directAccessGrantsEnabled=true)

# 5a. Audience mapper: stamp "aud: mcp-gateway" on the token
kc create "clients/$CLI/protocol-mappers/models" -r $REALM \
  -s name=audience-mcp-gateway \
  -s protocol=openid-connect \
  -s protocolMapper=oidc-audience-mapper \
  -s 'config."included.client.audience"=mcp-gateway' \
  -s 'config."access.token.claim"=true' \
  -s 'config."id.token.claim"=false'

# 5b. Role mapper: copy the user's mcp-gateway roles into a "roles" claim
kc create "clients/$CLI/protocol-mappers/models" -r $REALM \
  -s name=gateway-client-roles \
  -s protocol=openid-connect \
  -s protocolMapper=oidc-usermodel-client-role-mapper \
  -s 'config."usermodel.clientRoleMapping.clientId"=mcp-gateway' \
  -s 'config."claim.name"=roles' \
  -s 'config."jsonType.label"=String' \
  -s 'config."multivalued"=true' \
  -s 'config."access.token.claim"=true' \
  -s 'config."id.token.claim"=false'

# 6. Groups
DATA_TEAM=$(kc create groups -r $REALM -i -s name=data-team)
BI_TEAM=$(kc create groups -r $REALM -i -s name=bi-team)

# attach one mcp-gateway role to each group
kc add-roles -r $REALM --gname data-team --cclientid mcp-gateway --rolename data_engineer
kc add-roles -r $REALM --gname bi-team   --cclientid mcp-gateway --rolename bi_engineer

TEST_USER_PASSWORD="${TEST_USER_PASSWORD:-password}"

# create a user, set a password, print the user's id
make_user() {
  local name=$1 uid
  uid=$(kc create users -r $REALM -i \
    -s username="$name" -s enabled=true -s emailVerified=true \
    -s firstName="${name%%.*}" -s lastName=user -s email="$name@example.com")
  kc set-password -r $REALM --username "$name" --new-password "$TEST_USER_PASSWORD"
  echo "$uid"
}

# put a user into a group
add_to_group() { # user_id group_id
  kc update "users/$1/groups/$2" -r $REALM -s realm=$REALM -s userId="$1" -s groupId="$2" -n
}

# 7. Users
make_user analyst.user >/dev/null
kc add-roles -r $REALM --uusername analyst.user --cclientid mcp-gateway --rolename analyst

U=$(make_user engineer.user)
add_to_group "$U" "$DATA_TEAM"

U=$(make_user multi.user)
add_to_group "$U" "$DATA_TEAM"
add_to_group "$U" "$BI_TEAM"

make_user admin.user >/dev/null
kc add-roles -r $REALM --uusername admin.user --cclientid mcp-gateway --rolename data_admin

make_user nobody.user >/dev/null
