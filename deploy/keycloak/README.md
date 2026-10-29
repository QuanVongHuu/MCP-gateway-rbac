# deploy/keycloak

**What:** Keycloak, the identity provider. It issues the tokens whose `roles` claim drives all tool access.

**Contains:**
- `namespace.yaml`: namespace `keycloak`.
- `realm-config.yaml`: realm `mcp`, protected resource `mcp-gateway`, capability roles and one confidential service-account client per AI Agent.
- `keycloak.yaml`: Keycloak 26.2.5 dev Deployment and Service. The realm is imported at startup and secrets are resolved from environment variables backed by Kubernetes Secrets.

**README mapping:** *Authentication* checkpoint; *Test users* table. Build step 3, guideline §3.

**Check:** each client-credentials token has `aud=mcp-gateway`, `azp=<agent-client-id>` and exactly the roles in `tests/expected/agent-tool-access.json`.

**Secrets:** run `scripts/bootstrap-agent-secrets.sh`; never commit or print the generated values. Realm import is skipped when the realm already exists, so secret rotation requires updating both Keycloak and the Kubernetes Secret deliberately.
