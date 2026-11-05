#!/usr/bin/env bash
# Measure repeatable local-kind startup and RBAC verification runs.
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output_dir=${OUTPUT_DIR:-"$repo_dir/evidence/benchmarks"}
scenario=${1:-warm}
runs=${2:-5}
append=${BENCHMARK_APPEND:-false}

if [[ "$scenario" != warm && "$scenario" != workload-cold ]]; then
  echo "Usage: $0 {warm|workload-cold} [runs]" >&2
  exit 2
fi
[[ "$runs" =~ ^[1-9][0-9]*$ ]] || { echo "runs must be a positive integer" >&2; exit 2; }

mkdir -p "$output_dir"
csv="$output_dir/${scenario}.csv"
markdown="$output_dir/${scenario}.md"
if [[ "$append" == true && -f "$csv" ]]; then
  run_offset=$(( $(wc -l <"$csv") - 1 ))
else
  run_offset=0
  printf 'scenario,run,startup_seconds,gateway_ready_seconds,grafana_ready_seconds,rbac_seconds,allow_events,deny_events,rbac_status\n' >"$csv"
fi

now_ns() { date +%s%N; }
seconds_since() {
  awk -v start="$1" -v end="$(now_ns)" 'BEGIN { printf "%.3f", (end - start) / 1000000000 }'
}

gateway_pf= keycloak_pf= grafana_pf=
cleanup() {
  for pid in "$gateway_pf" "$keycloak_pf" "$grafana_pf"; do
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT

start_port_forwards() {
  cleanup
  kubectl -n agentgateway-system port-forward deployment/agentgateway-proxy 18080:80 >"$output_dir/gateway-port-forward.log" 2>&1 & gateway_pf=$!
  kubectl -n keycloak port-forward svc/keycloak 18002:8080 >"$output_dir/keycloak-port-forward.log" 2>&1 & keycloak_pf=$!
  kubectl -n observability port-forward svc/grafana 13000:3000 >"$output_dir/grafana-port-forward.log" 2>&1 & grafana_pf=$!
  for _ in {1..30}; do
    curl -fsS http://127.0.0.1:18002/realms/mcp/.well-known/openid-configuration >/dev/null 2>&1 && \
      curl -fsS -u admin:admin http://127.0.0.1:13000/api/health >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "Timed out waiting for local port-forwards" >&2
  return 1
}

reset_workloads() {
  # This preserves kind, agentgateway CRDs and cached images. It is not a true cold cluster start.
  kubectl delete namespace mcp keycloak observability --ignore-not-found --wait=true --timeout=240s
}

for iteration in $(seq 1 "$runs"); do
  run=$((run_offset + iteration))
  if [[ "$scenario" == workload-cold ]]; then
    reset_workloads
  fi

  started=$(now_ns)
  bash "$repo_dir/scripts/up.sh" >"$output_dir/${scenario}-${run}-startup.log" 2>&1
  bash "$repo_dir/observability/grafana/up.sh" >>"$output_dir/${scenario}-${run}-startup.log" 2>&1
  if [[ "$scenario" == workload-cold ]]; then
    # A recreated Keycloak realm has new signing keys; restart the proxy to discard its JWKS cache.
    kubectl -n agentgateway-system rollout restart deployment/agentgateway-proxy >>"$output_dir/${scenario}-${run}-startup.log" 2>&1
    kubectl -n agentgateway-system rollout status deployment/agentgateway-proxy --timeout=180s >>"$output_dir/${scenario}-${run}-startup.log" 2>&1
  fi
  startup_seconds=$(seconds_since "$started")

  start_port_forwards
  gateway_ready_seconds=$(seconds_since "$started")
  grafana_ready_seconds=$gateway_ready_seconds

  test_started=$(now_ns)
  audit_started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  if GATEWAY_URL=http://127.0.0.1:18080/mcp KEYCLOAK_TOKEN_URL=http://127.0.0.1:18002/realms/mcp/protocol/openid-connect/token \
    bash "$repo_dir/scripts/run-agent-rbac-tests.sh" >"$output_dir/${scenario}-${run}-rbac.log" 2>&1; then
    rbac_status=PASS
  else
    rbac_status=FAIL
  fi
  rbac_seconds=$(seconds_since "$test_started")
  gateway_pod=$(kubectl -n agentgateway-system get pod -l app.kubernetes.io/name=agentgateway-proxy -o jsonpath='{.items[0].metadata.name}')
  allow_events=$(timeout 5s kubectl -n agentgateway-system logs "$gateway_pod" --since-time="$audit_started" 2>/dev/null | grep -F 'mcp.method.name=tools/call' | grep -F 'http.status=200' | wc -l | tr -d ' ' || true)
  deny_events=$(timeout 5s kubectl -n agentgateway-system logs "$gateway_pod" --since-time="$audit_started" 2>/dev/null | grep -F 'mcp.method.name=tools/call' | grep -F 'http.status=400' | grep -F 'Unknown tool' | wc -l | tr -d ' ' || true)
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' "$scenario" "$run" "$startup_seconds" "$gateway_ready_seconds" "$grafana_ready_seconds" "$rbac_seconds" "$allow_events" "$deny_events" "$rbac_status" >>"$csv"
  [[ "$rbac_status" == PASS ]] || { echo "RBAC smoke failed on ${scenario} run ${run}" >&2; exit 1; }
done

awk -F, -v label="$scenario" '
  NR == 1 { next }
  { startup += $3; gateway += $4; grafana += $5; rbac += $6; success += ($9 == "PASS");
    if (NR == 2 || $3 < startup_min) startup_min = $3;
    if (NR == 2 || $3 > startup_max) startup_max = $3 }
  END {
    printf "# %s benchmark\n\n", label
    printf "| Runs | Startup min (s) | Startup mean (s) | Startup max (s) | Gateway ready mean (s) | Grafana ready mean (s) | RBAC mean (s) | RBAC pass rate |\n"
    printf "|---:|---:|---:|---:|---:|---:|---:|---:|\n"
    printf "| %d | %.3f | %.3f | %.3f | %.3f | %.3f | %.3f | %d/%d |\n", NR - 1, startup_min, startup / (NR - 1), startup_max, gateway / (NR - 1), grafana / (NR - 1), rbac / (NR - 1), success, NR - 1
  }
' "$csv" >"$markdown"

echo "Wrote $csv and $markdown"
