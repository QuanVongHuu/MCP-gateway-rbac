# deploy/identity

**What:** per-backend identity for backends that need a real token instead of headers. Today that is OpenMetadata.

**Contains (planned):**
- `openmetadata.yaml`: an `AgentgatewayPolicy` doing OAuth token exchange at Keycloak, so the backend receives a token whose audience is only `openmetadata`.

**README mapping:** the token-exchange half of the *Identity* checkpoint. Build step 5, guideline §5.

**Answered 9/10/2026:** the field is `backend.auth.oauthTokenExchange`, and `sectionName` on the `AgentgatewayBackend` target limits it to one MCP target, so OpenMetadata stays in the shared backend. It depends on `deploy/auth/jwt.yaml` (which hands over the caller's token in `x-caller-token`) and on Secret `mcp-gateway-client-secret` in namespace `mcp`, which is not in git.

**Check:** the exchange works against Keycloak directly with `curl` first, then through the gateway.
