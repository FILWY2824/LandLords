$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:DART_SUPPRESS_ANALYTICS = "true"

$root = Split-Path -Parent $PSCommandPath

Push-Location $root
try {
  Write-Host "[landlords-build] flutter build windows"
  & flutter build windows
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows failed with exit code $LASTEXITCODE"
  }

  $output = Join-Path $root "build\windows\x64\runner\Release\landlords.exe"
  if (-not (Test-Path $output)) {
    throw "Windows release output not found: $output"
  }

  Write-Host "[landlords-build] output=$output"
} finally {
  Pop-Location
}
