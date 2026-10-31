"""Verify Keycloak service-account claims and the agent x tool RBAC matrix.

Requires Keycloak on localhost:8002, agentgateway on localhost:8080, the
secrets named by tests/expected/agent-tool-access.json in the environment,
and mcp==1.30.0.
"""
import asyncio
import base64
import json
import os
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

from gateway_smoke import CASES


ROOT = Path(__file__).resolve().parents[1]
MATRIX_PATH = ROOT / "tests" / "expected" / "agent-tool-access.json"
GATEWAY_URL = os.getenv("GATEWAY_URL", "http://127.0.0.1:8080/mcp")
TOKEN_URL = os.getenv(
    "KEYCLOAK_TOKEN_URL",
    "http://127.0.0.1:8002/realms/mcp/protocol/openid-connect/token",
)


def get_token(client_id: str, client_secret: str) -> str:
    body = urlencode(
        {
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
        }
    ).encode()
    request = Request(TOKEN_URL, data=body, method="POST")
    request.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urlopen(request, timeout=15) as response:
        token = json.load(response).get("access_token")
    if not token:
        raise AssertionError(f"Keycloak returned no access token for {client_id}")
    return token


def decode_claims(token: str) -> dict:
    encoded = token.split(".")[1]
    encoded += "=" * (-len(encoded) % 4)
    return json.loads(base64.urlsafe_b64decode(encoded))


async def verify_agent(agent: dict, all_tools: list[str]) -> None:
    client_id = agent["client_id"]
    secret = os.getenv(agent["secret_env"])
    if not secret:
        raise RuntimeError(f"Missing required environment variable {agent['secret_env']}")

    token = get_token(client_id, secret)
    claims = decode_claims(token)
    audience = claims.get("aud", [])
    audience = [audience] if isinstance(audience, str) else audience
    assert "mcp-gateway" in audience, f"{client_id}: bad aud={audience}"
    assert claims.get("azp") == client_id, f"{client_id}: bad azp={claims.get('azp')}"
    assert sorted(claims.get("roles", [])) == sorted(agent["roles"]), (
        f"{client_id}: expected roles={agent['roles']} actual={claims.get('roles', [])}"
    )

    headers = {"Authorization": f"Bearer {token}"}
    async with streamablehttp_client(
        GATEWAY_URL, headers=headers, terminate_on_close=False
    ) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            actual = sorted(tool.name for tool in (await session.list_tools()).tools)
            expected = sorted(agent["tools"])
            assert actual == expected, (
                f"{client_id}: tool catalog mismatch\nexpected={expected}\nactual={actual}"
            )

            if expected:
                allowed = expected[0]
                result = await session.call_tool(allowed, CASES[allowed])
                assert not result.isError, f"{client_id}: allowed tool {allowed} failed"
                body = json.loads(result.content[0].text)
                seen = body.get("seen_by_mock", {})
                assert seen.get("x_agent_id") == client_id, (
                    f"{client_id}: backend saw x-agent-id={seen.get('x_agent_id')}"
                )
                # Keycloak names a service-account user service-account-<client_id>
                assert seen.get("x_forwarded_user") == f"service-account-{client_id}", (
                    f"{client_id}: backend saw x-forwarded-user={seen.get('x_forwarded_user')}"
                )

    # A denied call is returned as HTTP 400 by agentgateway v1.5 and closes the
    # stream, so exercise it in a separate session and catch around the entire
    # transport context rather than only around call_tool().
    denied = next((tool for tool in all_tools if tool not in expected), None)
    if denied:
        rejected = False
        try:
            async with streamablehttp_client(
                GATEWAY_URL, headers=headers, terminate_on_close=False
            ) as (read, write, _):
                async with ClientSession(read, write) as session:
                    await session.initialize()
                    result = await session.call_tool(denied, CASES[denied])
                    rejected = result.isError
        except Exception:
            rejected = True
        assert rejected, f"{client_id}: denied tool {denied} succeeded"

    print(f"{client_id}: roles={agent['roles']} tools={len(agent['tools'])} PASS")


async def main() -> None:
    matrix = json.loads(MATRIX_PATH.read_text())
    assert sorted(matrix["all_tools"]) == sorted(CASES), (
        "Expected matrix and gateway smoke catalog have diverged"
    )
    for agent in matrix["agents"]:
        await verify_agent(agent, matrix["all_tools"])
    print("agent_rbac_smoke=PASS")


if __name__ == "__main__":
    asyncio.run(main())
