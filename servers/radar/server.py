"""Mock of radar's built-in MCP server (skyhook-io/radar, /mcp). Canned data, real tool names."""
from mcp.server.fastmcp import Context

from mockkit import new_server, seen

TARGET = "radar"
mcp = new_server(TARGET)

NAMESPACES = ["data-platform", "spark-jobs", "airflow", "openmetadata", "trino", "lakekeeper"]
PODS = {
    "spark-jobs": [
        {"kind": "Pod", "name": "daily-sales-agg-driver", "status": "Running", "restarts": 0},
        {"kind": "Pod", "name": "spark-history-server-7d9f8", "status": "Running", "restarts": 1},
    ],
    "airflow": [
        {"kind": "Pod", "name": "airflow-scheduler-0", "status": "Running", "restarts": 0},
        {"kind": "Pod", "name": "airflow-api-server-5c6d7", "status": "Running", "restarts": 0},
    ],
    "trino": [{"kind": "Pod", "name": "trino-coordinator-0", "status": "CrashLoopBackOff", "restarts": 12}],
}
DEPLOYMENTS = {
    "trino": [{"kind": "Deployment", "name": "trino-worker", "ready": "3/4"}],
    "airflow": [{"kind": "Deployment", "name": "airflow-api-server", "ready": "1/1"}],
}


@mcp.tool()
def list_namespaces(ctx: Context) -> dict:
    """List all namespaces in the cluster."""
    who = seen(ctx, TARGET, "list_namespaces", {})
    return {"namespaces": NAMESPACES, "seen_by_mock": who}


@mcp.tool()
def list_resources(ctx: Context, kind: str, namespace: str = "", group: str = "", context: str = "") -> dict:
    """List minified summaries of resources of one kind (e.g. pods, deployments), optionally in one namespace."""
    who = seen(ctx, TARGET, "list_resources", {"kind": kind, "namespace": namespace})
    source = PODS if kind.lower() in ("pod", "pods") else DEPLOYMENTS
    items = source.get(namespace, []) if namespace else [i for v in source.values() for i in v]
    return {"kind": kind, "namespace": namespace or "*", "items": items, "seen_by_mock": who}


@mcp.tool()
def get_pod_logs(ctx: Context, namespace: str, name: str, container: str = "", tail_lines: int = 50,
                 grep: str = "", previous: bool = False, since: str = "") -> dict:
    """Get recent logs of one pod (secrets redacted)."""
    who = seen(ctx, TARGET, "get_pod_logs", {"namespace": namespace, "name": name, "tail_lines": tail_lines})
    lines = [
        f"2026-09-30T08:00:01Z INFO  starting {name}",
        "2026-09-30T08:00:02Z INFO  connecting to catalog lakekeeper.lakekeeper.svc:8181 password=[REDACTED]",
        "2026-09-30T08:00:05Z WARN  slow response from s3://lakehouse-bronze (1.8s)",
    ]
    if grep:
        lines = [line for line in lines if grep in line]
    return {"namespace": namespace, "pod": name, "lines": lines[-tail_lines:], "seen_by_mock": who}


@mcp.tool()
def manage_workload(ctx: Context, action: str, kind: str, namespace: str, name: str,
                    replicas: int | None = None, revision: int | None = None) -> dict:
    """WRITE: restart, scale or roll back a Deployment/StatefulSet/DaemonSet. Mock: nothing is changed."""
    who = seen(ctx, TARGET, "manage_workload",
               {"action": action, "kind": kind, "namespace": namespace, "name": name, "replicas": replicas})
    return {"result": f"mock: {action} {kind}/{name} in {namespace} accepted (no change made)", "seen_by_mock": who}


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
