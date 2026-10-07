"""Start each mock, list its tools, call one tool with identity headers + a fake JWT.

Run: python servers/smoke_test.py   (needs: pip install "mcp==1.30.0"; mock logs go to the temp dir)
"""
import asyncio
import base64
import json
import os
import subprocess
import sys
import tempfile
import time

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

HERE = os.path.dirname(os.path.abspath(__file__))
CASES = {
    "radar": ("list_namespaces", {}),
    "spark-history": ("get_job_bottlenecks", {"app_id": "spark-91be02"}),
    "openmetadata": ("search_metadata", {"query": "orders"}),
    "dbt": ("get_model_health", {"name": "stg_orders"}),
    "airflow": ("list_dags", {}),
}


def fake_jwt() -> str:
    enc = lambda d: base64.urlsafe_b64encode(json.dumps(d).encode()).rstrip(b"=").decode()
    return f"{enc({'alg': 'none'})}.{enc({'sub': 'u1', 'preferred_username': 'analyst.user', 'aud': 'openmetadata'})}.sig"


async def check(name: str, port: int) -> None:
    headers = {"X-Forwarded-User": "analyst.user", "X-Forwarded-Groups": "analyst", "Authorization": f"Bearer {fake_jwt()}"}
    async with streamablehttp_client(f"http://127.0.0.1:{port}/mcp", headers=headers) as (r, w, _):
        async with ClientSession(r, w) as s:
            await s.initialize()
            tools = [t.name for t in (await s.list_tools()).tools]
            tool, args = CASES[name]
            res = await s.call_tool(tool, args)
            body = json.loads(res.content[0].text)
            print(f"{name:14} tools={tools}")
            print(f"{'':14} {tool} -> seen_by_mock.user={body['seen_by_mock']['x_forwarded_user']} "
                  f"token.aud={body['seen_by_mock'].get('token', {}).get('aud')} isError={res.isError}")


async def main() -> None:
    procs = []
    env = {**os.environ, "PYTHONPATH": HERE}
    for i, name in enumerate(CASES):
        port = 18100 + i
        procs.append(subprocess.Popen([sys.executable, os.path.join(HERE, name, "server.py")],
                                      env={**env, "PORT": str(port)},
                                      stdout=open(os.path.join(tempfile.gettempdir(), f"mock-{name}.log"), "w"),
                                      stderr=subprocess.STDOUT))
    time.sleep(4)
    try:
        for i, name in enumerate(CASES):
            await check(name, 18100 + i)
    finally:
        for p in procs:
            p.terminate()


asyncio.run(main())
