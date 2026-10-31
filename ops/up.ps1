<#
.SYNOPSIS
  Brings the whole system up with one command on the existing kind cluster. Safe to re-run.
  PowerShell port of run.sh; the Kubernetes layers and the real servers still run their bash
  scripts (Git Bash must be on PATH).

  .\ops\up.ps1          start everything and wait until the gateway answers
  .\ops\up.ps1 -Test    the same, then run scripts/run-tests.sh and the AI Agent RBAC smoke test

  Run ./bootstrap.sh once before the first run (QUICKSTART.md). Stop with .\ops\down.ps1.
#>
[CmdletBinding()]
param([switch]$Test)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$started = Get-Date

function Step($name) { Write-Host "`n==== $name" -ForegroundColor Cyan }
function Die($msg) { Write-Error "up.ps1: $msg"; exit 1 }

# native commands do not throw on a non-zero exit code
function Run {
    & $args[0] $args[1..($args.Count - 1)]
    if ($LASTEXITCODE -ne 0) { Die "'$($args -join ' ')' failed (exit $LASTEXITCODE)" }
}

function HttpCode([string]$url, [hashtable]$headers = @{}, [string]$body) {
    try {
        $p = @{ Uri = $url; Headers = $headers; TimeoutSec = 5; UseBasicParsing = $true }
        if ($body) { $p.Method = "Post"; $p.Body = $body; $p.ContentType = "application/json" }
        (Invoke-WebRequest @p).StatusCode
    } catch {
        if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
    }
}

function WaitFor([string]$what, [int]$timeoutSec, [scriptblock]$check) {
    Write-Host "waiting for $what ..."
    $deadline = (Get-Date).AddSeconds($timeoutSec)
    while (-not (& $check)) {
        if ((Get-Date) -gt $deadline) { Die "timed out waiting for $what" }
        Start-Sleep -Seconds 5
    }
}

# skipped when the port already answers
function Forward([int]$port, [string]$ns, [string]$resource, [int]$remote) {
    if ((HttpCode "http://localhost:$port/") -ne 0) {
        Write-Host "localhost:$port already answers, keeping it"
    } else {
        $p = Start-Process kubectl -ArgumentList "port-forward -n $ns $resource ${port}:$remote" -WindowStyle Hidden -PassThru
        Write-Host "port-forward localhost:$port -> $ns ${resource}:$remote (background, pid $($p.Id))"
    }
}

function Token([string]$user) {
    $pw = if ($env:TEST_USER_PASSWORD) { $env:TEST_USER_PASSWORD } else { "password" }
    try {
        (Invoke-RestMethod -Method Post -TimeoutSec 15 -Uri "http://localhost:8002/realms/mcp/protocol/openid-connect/token" `
            -Body @{ grant_type = "password"; client_id = "mcp-cli"; username = $user; password = $pw }).access_token
    } catch { $null }
}

function GatewayReady {
    $t = Token "engineer.user"
    if (-not $t) { return $false }
    $init = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"up.ps1","version":"1"}}}'
    (HttpCode "http://localhost:8080/mcp" @{ Authorization = "Bearer $t"; Accept = "application/json, text/event-stream" } $init) -eq 200
}

Step "0. Preflight"
foreach ($tool in "kubectl", "helm", "docker", "bash", "jq") {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { Die "$tool is not installed (README: Requirements)" }
}
docker info *> $null; if ($LASTEXITCODE -ne 0) { Die "Docker is not running" }
# the cluster name is fixed: the OpenMetadata container reaches Keycloak at gatewayapi-control-plane
if ((kubectl config current-context) -ne "kind-gatewayapi") { Die "kubectl context is not kind-gatewayapi (run ./bootstrap.sh)" }
kubectl get crd agentgatewaypolicies.agentgateway.dev *> $null
if ($LASTEXITCODE -ne 0) { Die "agentgateway is not installed (run ./bootstrap.sh)" }
if (-not (docker exec gatewayapi-control-plane crictl images 2>$null | Select-String mcp-mocks)) {
    Die "the mock image is not in the cluster (run ./bootstrap.sh)"
}
Write-Host "ok"

Step "1. Kubernetes layers: gateway, mocks, Keycloak + realm, agents, policies"
Run bash scripts/up.sh

Step "2. Real radar (Helm, namespace mcp)"
Run kubectl apply -f deploy/real-servers/radar/rbac.yaml
helm repo add skyhook https://skyhook-io.github.io/helm-charts *> $null
Run helm upgrade -i radar-real skyhook/radar --version 1.16.0 -n mcp -f deploy/real-servers/radar/values.yaml --wait --timeout 5m

Step "3. Real OpenMetadata and Spark History Server MCP (Docker; the first run pulls about 4 GB)"
Run bash deploy/real-servers/openmetadata/up.sh
Run bash deploy/real-servers/spark-history/up.sh

Step "4. Port-forwards and Grafana"
Run kubectl rollout status deploy/agentgateway-proxy -n agentgateway-system --timeout=300s
Forward 8080 agentgateway-system deployment/agentgateway-proxy 80
Forward 8002 keycloak svc/keycloak 80
Run bash observability/grafana/up.sh
Forward 3000 observability svc/grafana 3000
WaitFor "Keycloak on localhost:8002" 120 { [bool](Token "admin.user") }

Step "5. OpenMetadata content: test users and a sample table"
WaitFor "OpenMetadata on localhost:8585" 600 { (HttpCode "http://localhost:8585/api/v1/system/version") -eq 200 }
Run bash deploy/real-servers/openmetadata/setup.sh

Step "6. Gateway"
# after a realm rebuild the gateway may reject tokens until its key cache (5 minutes) refreshes
WaitFor "the gateway to accept a token and reach every target" 600 { GatewayReady }

Write-Host @"

The system is up in $([int]((Get-Date) - $started).TotalSeconds)s.

  MCP endpoint    http://localhost:8080/mcp        send "Authorization: Bearer <token>"
  Keycloak        http://localhost:8002            admin / admin
  OpenMetadata    http://localhost:8585
  Grafana         http://localhost:3000            admin / admin  (MCP Gateway - Allow and Deny)
  Tests           .\ops\up.ps1 -Test

Port-forwards run as hidden kubectl processes; a reboot ends them, and .\ops\up.ps1 starts them again.
"@

if ($Test) {
    Step "7. Tests"
    Run bash scripts/run-tests.sh
    Run bash scripts/run-agent-rbac-tests.sh
}
