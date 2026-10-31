# tests/inspector

**What:** scripted calls through the normal client path, using MCP Inspector in `--cli` mode, one run per test user.

**Contains:**
- `run.sh`: fetches a token for each user, runs `tools/list` and the `tools/call` cases against `http://localhost:8080/mcp`, and compares the results with `tests/expected/`. Run it alone or through `scripts/run-tests.sh`. A failure prints the missing and unexpected tools, or the expected and actual outcome of a call.

**README mapping:** *Trying it*; build step 7, guideline §8.

**Rules:** always point at the gateway's `/mcp`, never at a backend. Needs Node 22.19+. Inspector is pinned to 0.21.2, where the header flag is `--header`.

**Not here:** adversarial, hand-built requests (see `tests/curl/`).
