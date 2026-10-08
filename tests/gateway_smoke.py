import asyncio
import os
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


GATEWAY_URL = os.getenv(
    "GATEWAY_URL",
    "http://127.0.0.1:8080/mcp",
)

CASES = {
    "airflow_get_dag_run": {
        "dag_id": "dbt_build_marts",
        "dag_run_id": "manual__smoke",
    },
    "airflow_get_task_logs": {
        "dag_id": "dbt_build_marts",
        "dag_run_id": "manual__smoke",
        "task_id": "dbt_test",
    },
    "airflow_list_dags": {},
    "airflow_pause_dag": {
        "dag_id": "om_metadata_ingest",
    },
    "airflow_trigger_dag": {
        "dag_id": "sales_ingest",
        "conf": {"source": "smoke"},
    },
    "dbt_get_lineage": {
        "unique_id": "model.lakehouse.fct_daily_revenue",
    },
    "dbt_get_model_health": {
        "name": "stg_orders",
    },
    "dbt_list_metrics": {},
    "dbt_query_metrics": {
        "metrics": ["revenue"],
        "group_by": ["customer__segment"],
    },
    "dbt_test": {
        "selector": "stg_orders",
    },
    "openmetadata_get_entity_details": {
        "entityType": "table",
        "fqn": "trino.iceberg.sales.orders",
    },
    "openmetadata_get_entity_lineage": {
        "entityType": "table",
        "fqn": "trino.iceberg.marts.daily_revenue",
    },
    "openmetadata_patch_entity": {
        "entityType": "table",
        "fqn": "trino.iceberg.sales.orders",
        "patch": '[{"op":"replace","path":"/description","value":"smoke"}]',
    },
    "openmetadata_search_metadata": {
        "query": "orders",
    },
    "radar_get_pod_logs": {
        "namespace": "spark-jobs",
        "name": "daily-sales-agg-driver",
    },
    "radar_list_namespaces": {},
    "radar_list_resources": {
        "kind": "pods",
        "namespace": "spark-jobs",
    },
    "radar_manage_workload": {
        "action": "restart",
        "kind": "Deployment",
        "namespace": "airflow",
        "name": "airflow-api-server",
    },
    "spark-history_get_job_bottlenecks": {
        "app_id": "spark-91be02",
    },
    "spark-history_get_stage": {
        "app_id": "spark-91be02",
        "stage_id": 7,
    },
    "spark-history_list_applications": {},
}


async def main():
    assert len(CASES) == 21

    async with streamablehttp_client(
        GATEWAY_URL,
        terminate_on_close=False,
    ) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()

            actual = sorted(
                tool.name for tool in (await session.list_tools()).tools
            )
            expected = sorted(CASES)

            assert actual == expected, (
                f"Tool catalog mismatch\n"
                f"expected={expected}\n"
                f"actual={actual}"
            )

            print(f"tool_count={len(actual)}")
            print("\n".join(actual))

            for name, arguments in CASES.items():
                result = await session.call_tool(name, arguments)
                assert not result.isError, (
                    f"{name} failed: {result.content}"
                )
                print(f"{name}: isError={result.isError}")

    print("gateway_smoke=PASS")


if __name__ == "__main__":
    asyncio.run(main())
