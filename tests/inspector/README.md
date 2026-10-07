# tests/inspector

**What:** scripted calls through the normal client path, using MCP Inspector in `--cli` mode, one run per test user.

**Contains (planned):**
- Scripts that fetch a token for each user, then run `tools/list` and `tools/call` against `http://localhost:8080/mcp`, and compare results with `tests/expected/`.

**README mapping:** *Trying it*; build step 7, guideline §8.

**Rules:** always point at the gateway's `/mcp`, never at a backend. Needs Node 22.19+. The header flag name varies by Inspector version; check `--help`.

**Not here:** adversarial, hand-built requests (see `tests/curl/`).
