$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSCommandPath
$serverExeCandidates = @(
  (Join-Path $root "backend\server\build-vs-codex\Debug\landlords_server.exe"),
  (Join-Path $root "backend\server\build-vs\Debug\landlords_server.exe")
)
$onnxDirEasy = Join-Path $root "backend\ai_models\onnx\douzero_ADP"
$onnxDirNormal = Join-Path $root "backend\ai_models\onnx\sl"
$onnxDirHard = Join-Path $root "backend\ai_models\onnx\douzero_WP"

function Resolve-ServerExe {
  foreach ($candidate in $serverExeCandidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  $listed = $serverExeCandidates -join ", "
  throw "Backend server not found. Checked: $listed"
}

function Get-ListeningProcessIds([int]$Port) {
  $connections = @()
  try {
    $connections = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop
  } catch {
    $connections = @()
  }

  if ($connections.Count -gt 0) {
    return $connections | Select-Object -ExpandProperty OwningProcess -Unique
  }

  $matches = netstat -ano | Select-String "[:.]$Port\s+.*LISTENING\s+(\d+)$"
  if (-not $matches) {
    return @()
  }

  $ids = foreach ($match in $matches) {
    if ($match.Matches.Count -gt 0) {
      [int]$match.Matches[0].Groups[1].Value
    }
  }
  return $ids | Select-Object -Unique
}

function Wait-PortsReleased([int[]]$Ports, [int]$TimeoutMs = 5000) {
  $deadline = (Get-Date).AddMilliseconds($TimeoutMs)
  while ((Get-Date) -lt $deadline) {
    $stillBusy = $false
    foreach ($port in $Ports) {
      if ((Get-ListeningProcessIds $port).Count -gt 0) {
        $stillBusy = $true
        break
      }
    }
    if (-not $stillBusy) {
      return
    }
    Start-Sleep -Milliseconds 150
  }

  $busyPorts = @()
  foreach ($port in $Ports) {
    if ((Get-ListeningProcessIds $port).Count -gt 0) {
      $busyPorts += $port
    }
  }
  throw "Ports still busy after waiting: $($busyPorts -join ', ')"
}

function Ensure-ServerPortsAvailable([int[]]$Ports) {
  $listenerProcessIds = @()
  foreach ($port in $Ports) {
    $listenerProcessIds += Get-ListeningProcessIds $port
  }
  $listenerProcessIds = $listenerProcessIds | Select-Object -Unique

  foreach ($processId in $listenerProcessIds) {
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($null -eq $process) {
      continue
    }

    if ($process.ProcessName -ieq "landlords_server") {
      Write-Host "[landlords] stop stale server pid=$processId name=$($process.ProcessName)"
      Stop-Process -Id $processId -Force
      continue
    }

    $processPath = ""
    try {
      $processPath = $process.Path
    } catch {
      $processPath = "<path unavailable>"
    }

    throw "Port conflict on $($Ports -join ', '): process $($process.ProcessName) (PID $processId, $processPath) is already listening. Stop it first or override LANDLORDS_PORT / LANDLORDS_WS_PORT."
  }

  if ($listenerProcessIds.Count -gt 0) {
    Wait-PortsReleased -Ports $Ports
  }
}

$serverExe = Resolve-ServerExe

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
if (-not $env:LANDLORDS_PORT) { $env:LANDLORDS_PORT = "23001" }
if (-not $env:LANDLORDS_WS_PORT) { $env:LANDLORDS_WS_PORT = "23002" }

$tcpPort = [int]$env:LANDLORDS_PORT
$wsPort = [int]$env:LANDLORDS_WS_PORT
Ensure-ServerPortsAvailable -Ports @($tcpPort, $wsPort)

Write-Host "[landlords] backend=onnx"
Write-Host "[landlords] server=$serverExe"
Write-Host "[landlords] easy=$env:LANDLORDS_DOUZERO_ONNX_DIR_EASY"
Write-Host "[landlords] normal=$env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL"
Write-Host "[landlords] hard=$env:LANDLORDS_DOUZERO_ONNX_DIR_HARD"
Write-Host "[landlords] tcp_port=$tcpPort"
Write-Host "[landlords] ws_port=$wsPort"
Write-Host "[landlords] log_level=$env:LANDLORDS_LOG_LEVEL"
& $serverExe
