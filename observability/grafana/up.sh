#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."

kubectl apply -f observability/grafana/stack.yaml
kubectl apply -f observability/grafana/dashboard.yaml
kubectl rollout status deployment/loki -n observability --timeout=300s
kubectl rollout status deployment/alloy -n observability --timeout=300s
kubectl rollout status deployment/grafana -n observability --timeout=300s

echo "Grafana and Loki are ready. Port-forward Grafana with:"
echo "  kubectl port-forward -n observability svc/grafana 3000:3000"
