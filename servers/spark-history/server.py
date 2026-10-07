"""Mock of the Spark History Server MCP (kubeflow/mcp-apache-spark-history-server). Canned data, real tool names."""
from mcp.server.fastmcp import Context

from mockkit import new_server, seen

TARGET = "spark-history"
mcp = new_server(TARGET)

APPS = [
    {"id": "spark-7f3a1c", "name": "daily-sales-agg", "status": "COMPLETED", "duration_s": 1843, "spark_version": "4.1.2"},
    {"id": "spark-91be02", "name": "customer-360-iceberg-merge", "status": "FAILED", "duration_s": 622, "spark_version": "4.1.2"},
    {"id": "spark-c4d8e9", "name": "risk-score-backfill", "status": "RUNNING", "duration_s": 305, "spark_version": "4.1.2"},
]


@mcp.tool()
def list_applications(ctx: Context, status: list[str] | None = None, limit: int = 20, app_id: str = "",
                      server: str = "") -> dict:
    """List Spark applications, optionally filtered by status (RUNNING/COMPLETED/FAILED) or a single app_id."""
    who = seen(ctx, TARGET, "list_applications", {"status": status, "limit": limit, "app_id": app_id})
    apps = [a for a in APPS if (not status or a["status"] in status) and (not app_id or a["id"] == app_id)]
    return {"applications": apps[:limit], "seen_by_mock": who}


@mcp.tool()
def get_stage(ctx: Context, app_id: str, stage_id: int, attempt_id: int | None = None, server: str = "") -> dict:
    """Get one stage of an application with task metric summaries."""
    who = seen(ctx, TARGET, "get_stage", {"app_id": app_id, "stage_id": stage_id})
    return {
        "app_id": app_id,
        "stage_id": stage_id,
        "attempt_id": attempt_id or 0,
        "status": "COMPLETE",
        "num_tasks": 400,
        "input_bytes": 52_428_800_000,
        "shuffle_write_bytes": 9_663_676_416,
        "task_duration_ms": {"p25": 2100, "p50": 3400, "p75": 5200, "max": 94000},
        "seen_by_mock": who,
    }


@mcp.tool()
def get_job_bottlenecks(ctx: Context, app_id: str, top_n: int = 5, server: str = "") -> dict:
    """Find the slowest stages, skewed tasks and executor problems in an application."""
    who = seen(ctx, TARGET, "get_job_bottlenecks", {"app_id": app_id, "top_n": top_n})
    findings = [
        {"stage_id": 7, "issue": "data skew", "detail": "max task 94s vs median 3.4s on join key customer_id"},
        {"stage_id": 4, "issue": "spill", "detail": "12.4 GB spilled to disk; raise spark.executor.memory"},
        {"executor": "exec-3", "issue": "GC", "detail": "GC time 31% of task time"},
    ]
    return {"app_id": app_id, "bottlenecks": findings[:top_n], "seen_by_mock": who}


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
