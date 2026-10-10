#!/usr/bin/env bash
# Prints an access token for a test user. Needs the Keycloak port-forward on localhost:8002.
#   TOKEN=$(scripts/get-token.sh engineer.user)
# Test users' passwords are the part of the username before the dot (deploy/keycloak/setup-realm.sh).
set -euo pipefail

user=${1:?usage: get-token.sh <user>   e.g. engineer.user}
KEYCLOAK_URL=${KEYCLOAK_URL:-http://localhost:8002}

token=$(curl -s -m 15 -X POST "$KEYCLOAK_URL/realms/mcp/protocol/openid-connect/token" \
  -d grant_type=password -d client_id=mcp-cli -d username="$user" -d password="${user%%.*}" | jq -r '.access_token // empty')

if [ -z "$token" ]; then
  echo "get-token: no token for $user from $KEYCLOAK_URL (is the Keycloak port-forward running?)" >&2
  exit 1
fi
echo "$token"
