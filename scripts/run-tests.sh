#!/usr/bin/env bash
# Runs tests/curl and tests/inspector against the gateway and compares with tests/expected/.
# Exit code 0 only if everything passed. Start the two port-forwards first:
#   kubectl port-forward deployment/agentgateway-proxy -n agentgateway-system 8080:80
#   kubectl port-forward -n keycloak svc/keycloak 8002:80
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)

if [ "$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost:8080/mcp)" != 401 ]; then
  echo "run-tests: the gateway does not answer 401 on http://localhost:8080/mcp (port-forward running?)" >&2
  exit 2
fi
"$ROOT/scripts/get-token.sh" engineer.user >/dev/null || exit 2

failed=0
bash "$ROOT/tests/curl/run.sh" || failed=1
echo
bash "$ROOT/tests/inspector/run.sh" || failed=1
echo
[ "$failed" -eq 0 ] && echo "ALL TESTS PASSED" || echo "SOME TESTS FAILED"
exit "$failed"
