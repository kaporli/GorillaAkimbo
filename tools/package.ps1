# Builds dist/GorillaGrip-<version>.zip for Nexus (game-folder layout: r6/...).
param([string]$Version = "1.0.0")
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist "GorillaGrip-$Version.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $root "r6") -DestinationPath $zip
"Built $zip"
