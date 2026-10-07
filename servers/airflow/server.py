"""Mock of an Airflow 3.x MCP server (modelled on astronomer astro-airflow-mcp). Canned data."""
from mcp.server.fastmcp import Context

from mockkit import new_server, seen

TARGET = "airflow"
mcp = new_server(TARGET)

DAGS = [
    {"dag_id": "sales_ingest", "is_paused": False, "schedule": "@hourly", "owners": ["data-team"], "last_run_state": "success"},
    {"dag_id": "dbt_build_marts", "is_paused": False, "schedule": "0 2 * * *", "owners": ["bi-team"], "last_run_state": "failed"},
    {"dag_id": "om_metadata_ingest", "is_paused": True, "schedule": "0 */6 * * *", "owners": ["data-team"], "last_run_state": "success"},
]


@mcp.tool()
def list_dags(ctx: Context, limit: int = 100) -> dict:
    """List DAGs with schedule, owners, paused flag and last run state."""
    who = seen(ctx, TARGET, "list_dags", {"limit": limit})
    return {"dags": DAGS[:limit], "seen_by_mock": who}


@mcp.tool()
def get_dag_run(ctx: Context, dag_id: str, dag_run_id: str) -> dict:
    """Get one DAG run with its state and task states."""
    who = seen(ctx, TARGET, "get_dag_run", {"dag_id": dag_id, "dag_run_id": dag_run_id})
    return {"dag_id": dag_id, "dag_run_id": dag_run_id, "state": "failed",
            "tasks": {"dbt_run": "success", "dbt_test": "failed", "notify": "upstream_failed"}, "seen_by_mock": who}


@mcp.tool()
def get_task_logs(ctx: Context, dag_id: str, dag_run_id: str, task_id: str, try_number: int = 1) -> dict:
    """Get the log of one task try."""
    who = seen(ctx, TARGET, "get_task_logs",
               {"dag_id": dag_id, "dag_run_id": dag_run_id, "task_id": task_id, "try_number": try_number})
    return {"log": [f"[{task_id}] running dbt test --select marts",
                    "Failure in test not_null_stg_orders_customer_id (models/staging/schema.yml)",
                    "Done. PASS=17 WARN=1 ERROR=1"], "seen_by_mock": who}


@mcp.tool()
def trigger_dag(ctx: Context, dag_id: str, conf: dict | None = None) -> dict:
    """WRITE: trigger a new DAG run. Mock: nothing is triggered."""
    who = seen(ctx, TARGET, "trigger_dag", {"dag_id": dag_id, "conf": conf})
    return {"result": f"mock: run of {dag_id} queued (nothing triggered)", "seen_by_mock": who}


@mcp.tool()
def pause_dag(ctx: Context, dag_id: str) -> dict:
    """WRITE: pause a DAG. Mock: nothing is changed."""
    who = seen(ctx, TARGET, "pause_dag", {"dag_id": dag_id})
    return {"result": f"mock: {dag_id} paused (no change made)", "seen_by_mock": who}


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
