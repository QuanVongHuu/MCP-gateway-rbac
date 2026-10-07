# deploy/keycloak

**What:** Keycloak, the identity provider. It issues the tokens whose `roles` claim drives all tool access.

**Contains (planned):**
- Dev-mode Deployment + Service in namespace `keycloak` (Keycloak ≥ 26.2, `KC_HOSTNAME=http://localhost:8002`).
- Realm setup script (`kcadm.sh` or admin REST API) creating:
  - realm `mcp`
  - clients `mcp-gateway` (confidential, owns roles `data_admin`, `data_engineer`, `bi_engineer`, `analyst`), `openmetadata`, `mcp-cli` (public, test only)
  - mappers: audience → `mcp-gateway`, client roles → `roles` claim
  - groups `data-team`, `bi-team`
  - the five test users

**README mapping:** *Authentication* checkpoint; *Test users* table. Build step 3, guideline §3.

**Check:** a token for `multi.user` decodes to `roles: ["data_engineer", "bi_engineer"]`.

**Secrets:** do not commit the `mcp-gateway` client secret.
