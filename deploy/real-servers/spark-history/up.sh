#!/usr/bin/env bash
# Downloads the upstream sample event logs once, then starts Spark History Server and its MCP server.
set -euo pipefail
cd "$(dirname "$0")"

RAW=https://raw.githubusercontent.com/kubeflow/mcp-apache-spark-history-server/v1.0.1/examples/basic/events
for app in spark-110be3a8424d4a2789cb88134418217b spark-bcec39f6201b42b9925124595baad260 spark-cc4d115f011443d787f03a71a476a745; do
  dir=events/eventlog_v2_$app
  if [ ! -s "$dir/events_1_$app" ]; then
    mkdir -p "$dir"
    curl -fsSL -o "$dir/events_1_$app" "$RAW/eventlog_v2_$app/events_1_$app"
    : > "$dir/appstatus_$app"
  fi
done

docker compose -p spark-history-real -f compose.yml up -d
