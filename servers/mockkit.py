"""Shared helpers for the mock MCP backends: server factory + identity logging."""
import base64
import json
import os
import sys

from mcp.server.fastmcp import Context, FastMCP


def new_server(name: str) -> FastMCP:
    # 0.0.0.0 so the Service can reach it; stateless + JSON so any gateway replica can serve any request.
    return FastMCP(
        name,
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8000")),
        stateless_http=True,
        json_response=True,
    )


def _jwt_claims(token: str) -> dict:
    # Mock only: decode without verifying. The real backend (e.g. OpenMetadata) verifies against Keycloak's JWKS.
    try:
        payload = token.split(".")[1]
        payload += "=" * (-len(payload) % 4)
        return json.loads(base64.urlsafe_b64decode(payload))
    except Exception:
        return {"error": "not a JWT"}


def seen(ctx: Context, target: str, tool: str, args: dict) -> dict:
    """Log who called which tool, as this backend sees it. Never logs the token itself."""
    request = ctx.request_context.request
    headers = request.headers if request is not None else {}
    record = {
        "event": "tool_call",
        "target": target,
        "tool": tool,
        "args": args,
        "x_forwarded_user": headers.get("x-forwarded-user"),
        "x_forwarded_groups": headers.get("x-forwarded-groups"),
        "authorization_present": "authorization" in headers,
    }
    auth = headers.get("authorization", "")
    if auth.lower().startswith("bearer "):
        claims = _jwt_claims(auth[7:])
        record["token"] = {k: claims.get(k) for k in ("iss", "aud", "azp", "sub", "preferred_username", "roles")}
    print(json.dumps(record), file=sys.stdout, flush=True)
    return record
