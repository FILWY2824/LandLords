$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:DART_SUPPRESS_ANALYTICS = "true"

$root = Split-Path -Parent $PSCommandPath
$cmakeBuildDir = Join-Path $root "build\windows\x64"

Push-Location $root
try {
  Write-Host "[landlords-build] preparing Windows scaffold"
  & flutter build windows
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows failed with exit code $LASTEXITCODE"
  }

  if (-not (Test-Path $cmakeBuildDir)) {
    throw "CMake build directory not found: $cmakeBuildDir"
  }

  Write-Host "[landlords-build] cmake --build build/windows/x64 --config Debug"
  & cmake --build $cmakeBuildDir --config Debug
  if ($LASTEXITCODE -ne 0) {
    throw "cmake debug build failed with exit code $LASTEXITCODE"
  }

  $output = Join-Path $root "build\windows\x64\runner\Debug\landlords.exe"
  if (-not (Test-Path $output)) {
    throw "Windows debug output not found: $output"
  }

  Write-Host "[landlords-build] output=$output"
} finally {
  Pop-Location
}
