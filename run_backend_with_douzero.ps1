$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSCommandPath
$proxyScript = Join-Path $root "backend\ai_service\douzero_proxy\run_proxy.ps1"
$serverExe = Join-Path $root "backend\server\build-vs\Debug\landlords_server.exe"

if (-not (Test-Path $proxyScript)) {
  throw "Proxy script not found: $proxyScript"
}

if (-not (Test-Path $serverExe)) {
  throw "Backend server not found: $serverExe"
}

$env:LANDLORDS_BOT_ENDPOINT = "http://127.0.0.1:31001/choose_move"
$env:LANDLORDS_BOT_TIMEOUT_SECONDS = "20"
if (-not $env:LANDLORDS_LOG_LEVEL) {
  $env:LANDLORDS_LOG_LEVEL = "INFO"
}
if (-not $env:LANDLORDS_PROXY_LOG_LEVEL) {
  $env:LANDLORDS_PROXY_LOG_LEVEL = "INFO"
}
if (-not $env:LANDLORDS_DOUZERO_DEVICE) {
  $env:LANDLORDS_DOUZERO_DEVICE = "cpu"
}

$proxyProcess = Start-Process `
  -FilePath "powershell.exe" `
  -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $proxyScript `
  -WorkingDirectory $root `
  -PassThru

Start-Sleep -Seconds 3

try {
  & $serverExe
} finally {
  if ($proxyProcess -and -not $proxyProcess.HasExited) {
    Stop-Process -Id $proxyProcess.Id -Force
  }
}
