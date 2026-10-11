[CmdletBinding()]
param(
    [string]$ClusterName = "gatewayapi"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Error "kind was not found in PATH. Install kind before running this script."
    exit 1
}

Write-Host "Deleting kind cluster '$ClusterName'..."
& kind delete cluster --name $ClusterName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to delete kind cluster '$ClusterName' (exit code $LASTEXITCODE)."
    exit $LASTEXITCODE
}

Write-Host "Kind cluster '$ClusterName' deleted."
