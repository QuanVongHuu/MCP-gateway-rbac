# scripts

**What:** the things you do repeatedly, so long one-liners are not copied around.

**Contains:**
- `get-token.sh <user>`: fetch an access token from Keycloak, e.g. `TOKEN=$(scripts/get-token.sh engineer.user)`.
- `up.sh`: apply the `deploy/` layers in order (the build order lives here as executable code). Safe to re-run. It expects guideline §1 done and does not start the real servers (`deploy/real-servers/`).
- `run-tests.sh`: run `tests/curl/` and `tests/inspector/` and compare with `tests/expected/`. Exit code 0 only if all pass; takes about two minutes.

**Needs:** `kubectl`, `curl`, `jq`, Node 22.19+, and for the tests the two port-forwards (gateway on 8080, Keycloak on 8002).

**README mapping:** *How to leverage it* (the build order). Guideline §3 (token) and §8 (tests).

**Rule:** scripts orchestrate. Config belongs in `deploy/` and `rbac/`, not here.
