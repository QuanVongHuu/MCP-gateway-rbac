# Shared by tests/inspector/run.sh and tests/curl/run.sh: paths, the token helper and pass/fail counting.
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GATEWAY_URL=${GATEWAY_URL:-http://localhost:8080/mcp}
EXPECTED=$ROOT/tests/expected

PASSED=0
FAILED=0

token() { "$ROOT/scripts/get-token.sh" "$1"; }

# jq on Windows ends lines with \r\n; the \r would end up inside usernames and tool names
jq() { command jq "$@" | tr -d '\r'; }

pass() { PASSED=$((PASSED + 1)); echo "  ok    $1"; }
fail() { FAILED=$((FAILED + 1)); echo "  FAIL  $1"; [ -z "${2:-}" ] || echo "        $2"; }

# check <description> <expected> <actual>
check() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "expected: $2 | got: $3"; fi
}

summary() {
  echo "$1: $PASSED passed, $FAILED failed"
  [ "$FAILED" -eq 0 ]
}
