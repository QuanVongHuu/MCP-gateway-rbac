# deploy/auth

**What:** how the gateway authenticates callers and passes identity to backends as headers.

**Contains:**
- `jwt.yaml`: strict Keycloak JWT validation on the Gateway plus verified `x-agent-id`, `x-forwarded-user` and `x-forwarded-groups` replacement.
- `keycloak-reference-grant.yaml`: permits the cross-namespace JWKS Service reference.

**README mapping:** *Authentication* checkpoint and the header half of *Identity*. Build steps 4 and 5, guideline §4 and §5.

**Not here:** which role may call which tool (that is `rbac/`), and token exchange (that is `deploy/identity/`).

**Check:** missing/invalid/wrong-audience tokens are rejected; the radar mock sees the token's `azp`, not a forged identity header.
