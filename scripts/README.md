# scripts

**What:** the things you do repeatedly, so long one-liners are not copied around.

**Contains (planned):**
- `get-token.sh <user>`: fetch an access token from Keycloak.
- `up.sh`: apply the `deploy/` layers in order (the build order lives here as executable code).
- `run-tests.sh`: run `tests/inspector/` and `tests/curl/` and compare with `tests/expected/`.

**README mapping:** *How to leverage it* (the build order). Guideline §3 (token) and §8 (tests).

**Rule:** scripts orchestrate. Config belongs in `deploy/` and `rbac/`, not here.
