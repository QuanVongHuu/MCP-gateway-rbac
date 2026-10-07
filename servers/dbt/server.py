"""Mock of a dbt MCP server (modelled on dbt-labs/dbt-mcp: semantic layer, discovery, CLI). Canned data."""
from mcp.server.fastmcp import Context

from mockkit import new_server, seen

TARGET = "dbt"
mcp = new_server(TARGET)

METRICS = [
    {"name": "revenue", "type": "simple", "description": "Sum of order amount", "dimensions": ["metric_time", "customer__segment"]},
    {"name": "order_count", "type": "simple", "description": "Number of orders", "dimensions": ["metric_time", "customer__segment"]},
]
MODELS = {
    "fct_daily_revenue": {"last_run": "success", "tests": {"pass": 11, "warn": 1, "fail": 0}, "freshness": "pass"},
    "stg_orders": {"last_run": "success", "tests": {"pass": 6, "warn": 0, "fail": 1}, "freshness": "warn"},
}


@mcp.tool()
def list_metrics(ctx: Context, search: str = "") -> dict:
    """List semantic-layer metrics."""
    who = seen(ctx, TARGET, "list_metrics", {"search": search})
    return {"metrics": [m for m in METRICS if search.lower() in m["name"]], "seen_by_mock": who}


@mcp.tool()
def query_metrics(ctx: Context, metrics: list[str], group_by: list[str] | None = None, limit: int = 10) -> dict:
    """Query semantic-layer metrics, optionally grouped by dimensions."""
    who = seen(ctx, TARGET, "query_metrics", {"metrics": metrics, "group_by": group_by, "limit": limit})
    rows = [
        {"metric_time__day": "2026-09-28", "customer__segment": "retail", "revenue": 182340.5, "order_count": 4210},
        {"metric_time__day": "2026-09-29", "customer__segment": "retail", "revenue": 175002.0, "order_count": 4032},
    ]
    return {"rows": rows[:limit], "seen_by_mock": who}


@mcp.tool()
def get_model_health(ctx: Context, name: str) -> dict:
    """Quality status of one model: last run, test results, source freshness."""
    who = seen(ctx, TARGET, "get_model_health", {"name": name})
    return {"model": name, **MODELS.get(name, {"error": "model not found"}), "seen_by_mock": who}


@mcp.tool()
def get_lineage(ctx: Context, unique_id: str, depth: int = 3) -> dict:
    """Parents and children of a dbt node."""
    who = seen(ctx, TARGET, "get_lineage", {"unique_id": unique_id, "depth": depth})
    return {"unique_id": unique_id, "parents": ["model.lakehouse.stg_orders", "model.lakehouse.stg_customers"],
            "children": ["exposure.lakehouse.revenue_dashboard"], "seen_by_mock": who}


@mcp.tool()
def test(ctx: Context, selector: str = "") -> dict:
    """EXECUTE: run dbt data tests for a selector (dbt test --select ...). Mock: nothing is run."""
    who = seen(ctx, TARGET, "test", {"selector": selector})
    return {"result": f"mock: dbt test --select {selector or '*'} -> PASS=17 WARN=1 ERROR=1", "seen_by_mock": who}


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
