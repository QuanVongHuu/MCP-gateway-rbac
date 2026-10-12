#!/usr/bin/env bash
# The normal client path, with MCP Inspector in --cli mode (guideline §8), compared with tests/expected/:
#   1. tools/list per test user must equal tools.json exactly
#   2. each call in calls.json must be allowed or denied as stated
# A denied call is "Unknown tool" from the gateway; it never reaches a backend.
# Needs Node 22.19+, jq, and the port-forwards on 8080 (gateway) and 8002 (Keycloak).
set -uo pipefail
source "$(dirname "$0")/../lib.sh"

inspector() { # inspector <token> <args...>
  local token=$1; shift
  npx -y @modelcontextprotocol/inspector@0.21.2 --cli "$GATEWAY_URL" --transport http \
    --header "Authorization: Bearer $token" "$@" 2>&1
}

echo "tools/list per user"
for user in $(jq -r 'keys[]' "$EXPECTED/tools.json"); do
  want=$(jq -c --arg u "$user" '.[$u]' "$EXPECTED/tools.json")
  got=$(inspector "$(token "$user")" --method tools/list | jq -c '[.tools[].name] | sort' 2>/dev/null)
  if [ "$want" = "$got" ]; then
    pass "$user sees $(jq length <<<"$want") tools"
  else
    fail "$user tools/list differs from tests/expected/tools.json" \
      "missing: $(jq -nc --argjson w "$want" --argjson g "${got:-[]}" '$w - $g') | unexpected: $(jq -nc --argjson w "$want" --argjson g "${got:-[]}" '$g - $w')"
  fi
done

echo "tools/call"
while IFS= read -r case; do
  user=$(jq -r .user <<<"$case"); tool=$(jq -r .tool <<<"$case"); expect=$(jq -r .expect <<<"$case")
  args=()
  while IFS= read -r arg; do args+=(--tool-arg "$arg"); done < <(jq -r '.args | to_entries[] | "\(.key)=\(.value)"' <<<"$case")

  out=$(inspector "$(token "$user")" --method tools/call --tool-name "$tool" "${args[@]}")
  if grep -q "Unknown tool" <<<"$out"; then
    got=deny
  elif [ "$(jq -r 'if has("content") and .isError != true then "ok" else "no" end' <<<"$out" 2>/dev/null)" = "ok" ]; then
    got=allow
  else
    got="error: $(tr '\n' ' ' <<<"$out" | cut -c1-160)"
  fi
  check "$user -> $tool: $expect" "$expect" "$got"
done < <(jq -c '.[]' "$EXPECTED/calls.json")

summary "tests/inspector"
