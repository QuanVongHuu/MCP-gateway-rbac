# deploy/auth

**What:** how the gateway authenticates callers and passes identity to backends as headers.

**Contains (planned):**
- `jwt.yaml`: one `AgentgatewayPolicy` on the Gateway with
  - `jwtAuthentication` (Keycloak issuer, audience `mcp-gateway`, JWKS lookup)
  - a request `transformation` setting `x-forwarded-user` and `x-forwarded-groups` from verified claims

**README mapping:** *Authentication* checkpoint and the header half of *Identity*. Build steps 4 and 5, guideline §4 and §5.

**Not here:** which role may call which tool (that is `rbac/`), and token exchange (that is `deploy/identity/`).

**Check:** a request with no token is rejected; the radar mock logs the token's user, not a forged `X-Forwarded-User`.
