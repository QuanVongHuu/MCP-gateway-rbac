#!/usr/bin/env bash
# Hand-built requests a proper MCP client would never send (guideline §8; docs/03 §5 cases 9 and 13).
# Each one tries to get past authentication, identity or tool access:
#   - no token, or a token that is not a JWT
#   - forged X-Forwarded-User / X-Forwarded-Groups / X-Caller-Token headers
#   - two "name" keys in one call, one allowed and one denied
#   - a JSON-RPC batch mixing an allowed and a denied call
# The identity case reads seen_by_mock, so it uses a dbt tool: `dbt` must still be a mock target.
# Needs jq and the port-forwards on 8080 (gateway) and 8002 (Keycloak).
set -uo pipefail
source "$(dirname "$0")/../lib.sh"

JSON=(-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"tests-curl","version":"1"}}}'
ALLOWED='{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"dbt_list_metrics","arguments":{}}}'

status() { curl -s -m 20 -o /dev/null -w "%{http_code}" "$GATEWAY_URL" "${JSON[@]}" "$@"; }
# the JSON-RPC message of a response, whether it came as JSON or as an event stream
message() { sed 's/^data: //' | grep '^{' | head -1; }

echo "authentication"
check "no token is rejected" 401 "$(status -d "$INIT")"
check "a token that is not a JWT is rejected" 401 "$(status -H "Authorization: Bearer not-a-jwt" -d "$INIT")"
check "forged identity headers without a token are rejected" 401 \
  "$(status -H "X-Forwarded-User: admin.user" -H "X-Forwarded-Groups: data_admin" -d "$ALLOWED")"

# a session as engineer.user for the remaining cases
TOKEN=$(token engineer.user)
AUTH=(-H "Authorization: Bearer $TOKEN")
SID=$(curl -si -m 20 "$GATEWAY_URL" "${AUTH[@]}" "${JSON[@]}" -d "$INIT" | grep -i '^mcp-session-id' | awk '{print $2}' | tr -d '\r')
SESSION=("${AUTH[@]}" "${JSON[@]}" -H "Mcp-Session-Id: $SID")
curl -s -m 20 -o /dev/null "$GATEWAY_URL" "${SESSION[@]}" -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'

echo "identity (engineer.user sending forged headers)"
seen=$(curl -s -m 20 "$GATEWAY_URL" "${SESSION[@]}" \
  -H "X-Forwarded-User: admin.user" -H "X-Forwarded-Groups: data_admin" -H "X-Caller-Token: Bearer forged" \
  -d "$ALLOWED" | message | jq -c '.result.content[0].text | fromjson | .seen_by_mock' 2>/dev/null)
check "backend sees the token's user, not the forged one" engineer.user "$(jq -r .x_forwarded_user <<<"$seen" 2>/dev/null)"
check "backend sees the token's roles, not the forged ones" data_engineer "$(jq -r .x_forwarded_groups <<<"$seen" 2>/dev/null)"
check "backend receives no caller token" false "$(jq -r .authorization_present <<<"$seen" 2>/dev/null)"

echo "tool access (engineer.user may call dbt_list_metrics, not dbt_test)"
smuggle() { # smuggle <description> <body>: the request must not be answered with a result
  local body
  body=$(curl -s -m 20 "$GATEWAY_URL" "${SESSION[@]}" -d "$2")
  if grep -q '"result"' <<<"$body"; then fail "$1" "got a result: $(cut -c1-160 <<<"$body")"; else pass "$1"; fi
}
smuggle "two name keys, allowed first then denied" \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"dbt_list_metrics","name":"dbt_test","arguments":{}}}'
smuggle "two name keys, denied first then allowed" \
  '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"dbt_test","name":"dbt_list_metrics","arguments":{}}}'
smuggle "a batch with an allowed and a denied call" \
  '[{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"dbt_list_metrics","arguments":{}}},{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"dbt_test","arguments":{}}}]'
check "a denied tool called directly is an unknown tool" "Unknown tool: dbt_test" \
  "$(curl -s -m 20 "$GATEWAY_URL" "${SESSION[@]}" -d '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"dbt_test","arguments":{}}}' | message | jq -r .error.message 2>/dev/null)"

summary "tests/curl"
