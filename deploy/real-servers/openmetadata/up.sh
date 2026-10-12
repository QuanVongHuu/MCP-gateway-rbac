#!/usr/bin/env bash
# Starts the real OpenMetadata without the ingestion (Airflow) service. First run pulls about 3 GB.
set -euo pipefail
cd "$(dirname "$0")"
kubectl apply -f keycloak-nodeport.yaml
docker compose -p openmetadata-real -f upstream-compose.yml -f compose.override.yml \
  up -d postgresql elasticsearch execute-migrate-all openmetadata-server
