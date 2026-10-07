"""Mock of OpenMetadata's built-in MCP server (/mcp on the OM server). Canned data, real tool names."""
from mcp.server.fastmcp import Context

from mockkit import new_server, seen

TARGET = "openmetadata"
mcp = new_server(TARGET)

TABLES = {
    "trino.iceberg.sales.orders": {
        "entityType": "table", "owner": "data-team", "domain": "Sales", "tier": "Tier1",
        "tags": ["PII.None"], "columns": ["order_id", "customer_id", "amount", "order_ts"],
        "description": "One row per order, loaded hourly by Airflow DAG sales_ingest.",
    },
    "trino.iceberg.crm.customers": {
        "entityType": "table", "owner": "bi-team", "domain": "Customer", "tier": "Tier1",
        "tags": ["PII.Sensitive"], "columns": ["customer_id", "full_name", "phone", "segment"],
        "description": "Customer master data.",
    },
    "trino.iceberg.marts.daily_revenue": {
        "entityType": "table", "owner": "bi-team", "domain": "Sales", "tier": "Tier2",
        "tags": [], "columns": ["day", "segment", "revenue"],
        "description": "dbt model fct_daily_revenue.",
    },
}
LINEAGE = {
    "trino.iceberg.marts.daily_revenue": {
        "upstream": ["trino.iceberg.sales.orders", "trino.iceberg.crm.customers"], "downstream": ["superset.dashboard.revenue"],
    },
}


@mcp.tool()
def search_metadata(ctx: Context, query: str = "", entityType: str = "", size: int = 10) -> dict:
    """Search data assets by keyword, owner, tag, tier, service or column name."""
    who = seen(ctx, TARGET, "search_metadata", {"query": query, "entityType": entityType, "size": size})
    q = query.lower()
    hits = [{"fqn": fqn, **{k: v[k] for k in ("entityType", "owner", "domain", "tier")}}
            for fqn, v in TABLES.items()
            if (not q or q in fqn or q in v["description"].lower() or q in " ".join(v["columns"]))
            and (not entityType or v["entityType"] == entityType)]
    return {"total": len(hits), "results": hits[:size], "seen_by_mock": who}


@mcp.tool()
def get_entity_details(ctx: Context, entityType: str, fqn: str) -> dict:
    """Get full details of one entity by its fully qualified name."""
    who = seen(ctx, TARGET, "get_entity_details", {"entityType": entityType, "fqn": fqn})
    entity = TABLES.get(fqn)
    if entity is None:
        return {"error": f"{entityType} {fqn} not found", "seen_by_mock": who}
    return {"fqn": fqn, **entity, "seen_by_mock": who}


@mcp.tool()
def get_entity_lineage(ctx: Context, entityType: str, fqn: str, upstreamDepth: int = 3,
                       downstreamDepth: int = 3) -> dict:
    """Get upstream sources and downstream consumers of an entity."""
    who = seen(ctx, TARGET, "get_entity_lineage", {"entityType": entityType, "fqn": fqn})
    return {"fqn": fqn, **LINEAGE.get(fqn, {"upstream": [], "downstream": []}), "seen_by_mock": who}


@mcp.tool()
def patch_entity(ctx: Context, entityType: str, fqn: str, patch: str) -> dict:
    """WRITE: change an entity with a JSON Patch (e.g. description, tags, owner). Mock: nothing is changed."""
    who = seen(ctx, TARGET, "patch_entity", {"entityType": entityType, "fqn": fqn, "patch": patch})
    return {"result": f"mock: patch for {entityType} {fqn} accepted (no change made)", "seen_by_mock": who}


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
