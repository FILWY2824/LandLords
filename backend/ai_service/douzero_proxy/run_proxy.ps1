$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$python = "F:\pythonFile\anaconda\envs\anaconda_environment\python.exe"
$baselineDir = Join-Path $root "third_party\baselines\douzero_ADP"
$serverScript = Join-Path $PSScriptRoot "server.py"

if (-not (Test-Path $python)) {
  throw "Python env not found: $python"
}

if (-not (Test-Path $baselineDir)) {
  throw "Baseline dir not found: $baselineDir"
}

if (-not $env:LANDLORDS_DOUZERO_DEVICE) {
  $env:LANDLORDS_DOUZERO_DEVICE = "cpu"
}
if (-not $env:LANDLORDS_DOUZERO_PRELOAD) {
  $env:LANDLORDS_DOUZERO_PRELOAD = "1"
}
if (-not $env:LANDLORDS_DOUZERO_WARMUP) {
  $env:LANDLORDS_DOUZERO_WARMUP = "1"
}
if (-not $env:LANDLORDS_PROXY_LOG_LEVEL) {
  $env:LANDLORDS_PROXY_LOG_LEVEL = "INFO"
}

& $python $serverScript --host 127.0.0.1 --port 31001 --baseline-dir $baselineDir
