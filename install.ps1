<#
.SYNOPSIS
  Installs InferGauge for the current Windows user - no admin rights needed.
.DESCRIPTION
  Downloads the latest InferGauge binary from infergauge-releases, places it
  in %LOCALAPPDATA%\Programs\InferGauge, and adds that folder to your user
  PATH so `infergauge` works from any new terminal. Safe to re-run any time
  to upgrade to the latest version.

  This script itself lives in Nexus-InferGauge/InferGauge under
  packaging/install.ps1 and is kept in sync on every release to
  Nexus-InferGauge/infergauge-releases (see .github/workflows/release.yml's
  homebrew job) - that public, source-free copy is what
  `irm .../install.ps1 | iex` actually fetches.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # Invoke-WebRequest's progress bar is very slow on Windows PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$installDir = Join-Path $env:LOCALAPPDATA "Programs\InferGauge"
$zipUrl = "https://github.com/Nexus-InferGauge/infergauge-releases/releases/latest/download/infergauge-windows-x86_64.zip"
$zipPath = Join-Path $env:TEMP "infergauge-install.zip"

try {
    Write-Host "Downloading InferGauge..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

    Write-Host "Installing to $installDir..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
} catch {
    Write-Host ""
    Write-Host "Install failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "If infergauge is currently running, close it and try again." -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = @(); if ($userPath) { $pathEntries = $userPath -split ";" | Where-Object { $_ -ne "" } }

Write-Host ""
if ($pathEntries -notcontains $installDir) {
    Write-Host "Adding $installDir to your PATH..." -ForegroundColor Cyan
    $newPath = if ($userPath) { "$userPath;$installDir" } else { $installDir }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$env:PATH;$installDir"   # so `infergauge` also works in *this* session
    Write-Host "InferGauge installed. Open a NEW terminal window and run:" -ForegroundColor Green
} else {
    Write-Host "InferGauge updated to the latest version. Run:" -ForegroundColor Green
}
Write-Host "  infergauge init -y && infergauge run" -ForegroundColor White
Write-Host ""
Write-Host "First run may show a Windows SmartScreen warning (click More info," -ForegroundColor DarkGray
Write-Host "then Run anyway) until the binary is code-signed." -ForegroundColor DarkGray
