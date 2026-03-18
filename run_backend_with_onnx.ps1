$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSCommandPath
$serverExe = Join-Path $root "backend\server\build-vs\Debug\landlords_server.exe"
$onnxDirEasy = Join-Path $root "backend\ai_models\onnx\douzero_ADP"
$onnxDirNormal = Join-Path $root "backend\ai_models\onnx\sl"
$onnxDirHard = Join-Path $root "backend\ai_models\onnx\douzero_WP"

if (-not (Test-Path $serverExe)) {
  throw "Backend server not found: $serverExe"
}

if (-not (Test-Path (Join-Path $onnxDirEasy "landlord.onnx"))) {
  throw "Easy ONNX model not found under: $onnxDirEasy"
}

if (-not (Test-Path (Join-Path $onnxDirNormal "landlord.onnx"))) {
  throw "Normal ONNX model not found under: $onnxDirNormal"
}

if (-not (Test-Path (Join-Path $onnxDirHard "landlord.onnx"))) {
  throw "Hard ONNX model not found under: $onnxDirHard"
}

$env:LANDLORDS_BOT_BACKEND = "onnx"
$env:LANDLORDS_DOUZERO_ONNX_DIR = $onnxDirNormal
$env:LANDLORDS_DOUZERO_ONNX_DIR_EASY = $onnxDirEasy
$env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL = $onnxDirNormal
$env:LANDLORDS_DOUZERO_ONNX_DIR_HARD = $onnxDirHard
if (-not $env:LANDLORDS_LOG_LEVEL) {
  $env:LANDLORDS_LOG_LEVEL = "DEBUG"
}
if (-not $env:LANDLORDS_MANAGED_DELAY_MIN_MS) { $env:LANDLORDS_MANAGED_DELAY_MIN_MS = "380" }
if (-not $env:LANDLORDS_MANAGED_DELAY_MAX_MS) { $env:LANDLORDS_MANAGED_DELAY_MAX_MS = "680" }
if (-not $env:LANDLORDS_BOT_BID_DELAY_MIN_MS) { $env:LANDLORDS_BOT_BID_DELAY_MIN_MS = "260" }
if (-not $env:LANDLORDS_BOT_BID_DELAY_MAX_MS) { $env:LANDLORDS_BOT_BID_DELAY_MAX_MS = "460" }
if (-not $env:LANDLORDS_BOT_PLAY_DELAY_MIN_MS) { $env:LANDLORDS_BOT_PLAY_DELAY_MIN_MS = "320" }
if (-not $env:LANDLORDS_BOT_PLAY_DELAY_MAX_MS) { $env:LANDLORDS_BOT_PLAY_DELAY_MAX_MS = "520" }
if (-not $env:LANDLORDS_FINISH_DELAY_MS) { $env:LANDLORDS_FINISH_DELAY_MS = "520" }

Write-Host "[landlords] backend=onnx"
Write-Host "[landlords] easy=$env:LANDLORDS_DOUZERO_ONNX_DIR_EASY"
Write-Host "[landlords] normal=$env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL"
Write-Host "[landlords] hard=$env:LANDLORDS_DOUZERO_ONNX_DIR_HARD"
Write-Host "[landlords] log_level=$env:LANDLORDS_LOG_LEVEL"
& $serverExe
