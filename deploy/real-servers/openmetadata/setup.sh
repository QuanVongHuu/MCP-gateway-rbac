#!/usr/bin/env bash
# One-time content for the real OpenMetadata: the test users and one sample table, created through
# its API as admin.user (an OpenMetadata admin, see AUTHORIZER_ADMIN_PRINCIPALS). Safe to re-run.
# A user must exist here before their token is accepted; unknown users get 404.
# Needs the Keycloak port-forward on 8002 and OpenMetadata on localhost:8585.
set -euo pipefail

TOKEN=$("$(dirname "$0")/../../../scripts/get-token.sh" admin.user)

put() {
  curl -s -o /dev/null -w "$1 -> %{http_code}\n" -X PUT "http://localhost:8585/api/v1/$1" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$2"
}

for user in analyst.user engineer.user multi.user nobody.user; do
  put users "{\"name\":\"$user\",\"email\":\"$user@example.com\",\"displayName\":\"$user\"}"
done

put services/databaseServices '{"name":"trino","serviceType":"Trino","connection":{"config":{"type":"Trino","hostPort":"trino.trino.svc:8080","username":"openmetadata"}}}'
put databases '{"name":"iceberg","service":"trino"}'
put databaseSchemas '{"name":"sales","database":"trino.iceberg"}'
put tables '{"name":"orders","databaseSchema":"trino.iceberg.sales","description":"One row per customer order.","columns":[{"name":"order_id","dataType":"BIGINT"},{"name":"customer_id","dataType":"BIGINT"},{"name":"amount","dataType":"DECIMAL","precision":12,"scale":2},{"name":"ordered_at","dataType":"TIMESTAMP"}]}'
