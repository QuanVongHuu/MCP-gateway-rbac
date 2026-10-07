# tests/curl

**What:** edge cases that need a hand-built request, which a proper MCP client would never send.

**Contains (planned):**
- `curl` scripts for: duplicate `"name"` keys, JSON-RPC batches, forged `X-Forwarded-User` / `X-Forwarded-Groups` headers (docs/03 §5 cases 9 and 13).

**README mapping:** *Identity* and *Authorization* checkpoints; guideline §8.

**How:** send `initialize` first and reuse the returned `Mcp-Session-Id`. For the forged-header case, check the backend mock's log: it must show the token's user, not the forged one.

**Not here:** the normal per-user matrix (see `tests/inspector/`).
