[CmdletBinding()]
param(
    [string]$Distro = "Ubuntu"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    throw "wsl.exe was not found. Run scripts/up.sh from WSL instead."
}

$repoDir = (& wsl.exe -d $Distro -- wslpath -u $PSScriptRoot).Trim()
if ($LASTEXITCODE -ne 0 -or -not $repoDir) {
    throw "Could not resolve the repository path inside WSL distro '$Distro'."
}

$escapedRepoDir = $repoDir.Replace("'", "'\"'\"'")
$command = "cd '$escapedRepoDir' && bash scripts/up.sh && bash observability/grafana/up.sh"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
& wsl.exe -d $Distro -- bash -lc $command
$exitCode = $LASTEXITCODE
$stopwatch.Stop()

if ($exitCode -ne 0) {
    throw "Startup failed (exit code $exitCode) after $($stopwatch.Elapsed.ToString())."
}

Write-Host "System and Grafana are ready in $($stopwatch.Elapsed.ToString())."
