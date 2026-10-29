#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
kubectl_bin=${KUBECTL_BIN:-kubectl}
python_bin=${PYTHON_BIN:-python3}

command -v "$kubectl_bin" >/dev/null
command -v "$python_bin" >/dev/null

if "$python_bin" -c 'import mcp' >/dev/null 2>&1; then
  python_command=("$python_bin")
elif command -v uv >/dev/null; then
  python_command=(uv run --with mcp==1.30.0 python)
else
  echo "mcp==1.30.0 is not installed and uv is unavailable." >&2
  exit 1
fi

read_secret() {
  local key=$1
  "$kubectl_bin" -n keycloak get secret agent-client-secrets \
    -o "jsonpath={.data.${key}}" | base64 -d
}

export CLUSTER_OBSERVER_AGENT_SECRET=$(read_secret cluster-observer-agent)
export INCIDENT_RESPONSE_AGENT_SECRET=$(read_secret incident-response-agent)
export SPARK_DIAGNOSTIC_AGENT_SECRET=$(read_secret spark-diagnostic-agent)
export METADATA_DISCOVERY_AGENT_SECRET=$(read_secret metadata-discovery-agent)
export METADATA_STEWARD_AGENT_SECRET=$(read_secret metadata-steward-agent)
export DBT_QUALITY_AGENT_SECRET=$(read_secret dbt-quality-agent)
export AIRFLOW_MONITOR_AGENT_SECRET=$(read_secret airflow-monitor-agent)
export AIRFLOW_OPERATOR_AGENT_SECRET=$(read_secret airflow-operator-agent)
export PLATFORM_ADMIN_AGENT_SECRET=$(read_secret platform-admin-agent)
export NO_ACCESS_AGENT_SECRET=$(read_secret no-access-agent)

"${python_command[@]}" "$repo_dir/tests/agent_rbac_smoke.py"
