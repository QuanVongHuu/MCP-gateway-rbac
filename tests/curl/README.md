# tests/curl

**What:** edge cases that need a hand-built request, which a proper MCP client would never send.

**Contains:**
- `run.sh`: no token, a token that is not a JWT, forged `X-Forwarded-User` / `X-Forwarded-Groups` / `X-Caller-Token` headers, duplicate `"name"` keys, and a JSON-RPC batch (docs/03 §5 cases 9 and 13). Run it alone or through `scripts/run-tests.sh`.
- The forged-header case reads `seen_by_mock` from the response, so it calls a `dbt` tool: `dbt` must still be a mock target.

**README mapping:** *Identity* and *Authorization* checkpoints; guideline §8.

**How:** send `initialize` first and reuse the returned `Mcp-Session-Id`. For the forged-header case, check the backend mock's log: it must show the token's user, not the forged one.

**Not here:** the normal per-user matrix (see `tests/inspector/`).
