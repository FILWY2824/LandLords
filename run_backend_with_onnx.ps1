$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSCommandPath
$envLoader = Join-Path $root "tool\Load-LandlordsEnv.ps1"
if (Test-Path $envLoader) {
  . $envLoader
  $loadedEnv = Import-LandlordsEnv -RepoRoot $root
  if ($loadedEnv) {
    Write-Host "[landlords] loaded landlords.env"
  }
}

$serverExeCandidates = @(
  (Join-Path $root "backend\server\build-vs-codex\Debug\landlords_server.exe"),
  (Join-Path $root "backend\server\build-vs\Debug\landlords_server.exe")
)

function Resolve-RepoPath([string]$PathValue) {
  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    return $PathValue
  }
  if ([System.IO.Path]::IsPathRooted($PathValue)) {
    return $PathValue
  }
  return Join-Path $root $PathValue
}

function Resolve-ServerExe {
  $existing = @($serverExeCandidates | Where-Object { Test-Path $_ })
  if ($existing.Count -gt 0) {
    return $existing |
      Sort-Object { (Get-Item $_).LastWriteTimeUtc } -Descending |
      Select-Object -First 1
  }

  $listed = $serverExeCandidates -join ", "
  throw "Backend server not found. Checked: $listed"
}

function Get-ListeningProcessInfo([int[]]$Ports) {
  $listeners = @()

  try {
    foreach ($port in $Ports) {
      $connections = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction Stop
      foreach ($connection in $connections) {
        $listeners += [pscustomobject]@{
          Port = [int]$connection.LocalPort
          ProcessId = [int]$connection.OwningProcess
        }
      }
    }
  } catch {
    $listeners = @()
  }

  if ($listeners.Count -eq 0) {
    foreach ($entry in netstat -ano -p tcp) {
      if ($entry -notmatch "LISTENING") {
        continue
      }
      $tokens = ($entry -replace '^\s+', '') -split '\s+'
      if ($tokens.Count -lt 5) {
        continue
      }
      if ($tokens[0] -ne "TCP") {
        continue
      }
      if ($tokens[3] -ne "LISTENING") {
        continue
      }
      if ($tokens[1] -notmatch ":(\d+)$") {
        continue
      }
      $port = [int]$Matches[1]
      if ($port -notin $Ports) {
        continue
      }
      $listeners += [pscustomobject]@{
        Port = $port
        ProcessId = [int]$tokens[4]
      }
    }
  }

  $listeners = $listeners |
    Sort-Object Port, ProcessId -Unique |
    ForEach-Object {
      $process = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
      [pscustomobject]@{
        Port = $_.Port
        ProcessId = $_.ProcessId
        ProcessName = if ($process) { $process.ProcessName } else { $null }
        Path = if ($process) {
          try { $process.Path } catch { "<path unavailable>" }
        } else {
          $null
        }
      }
    }

  return @($listeners)
}

function Wait-PortsReleased([int[]]$Ports, [int]$TimeoutMs = 5000) {
  $deadline = (Get-Date).AddMilliseconds($TimeoutMs)
  while ((Get-Date) -lt $deadline) {
    if ((Get-ListeningProcessInfo -Ports $Ports).Count -eq 0) {
      return
    }
    Start-Sleep -Milliseconds 150
  }

  $busyPorts = (Get-ListeningProcessInfo -Ports $Ports | Select-Object -ExpandProperty Port -Unique)
  throw "Ports still busy after waiting: $($busyPorts -join ', ')"
}

function Ensure-ServerPortsAvailable([int[]]$Ports) {
  $listeners = Get-ListeningProcessInfo -Ports $Ports
  if ($listeners.Count -eq 0) {
    return
  }

  $listenersByProcess = $listeners | Group-Object ProcessId
  foreach ($group in $listenersByProcess) {
    $listener = $group.Group | Select-Object -First 1
    if ($listener.ProcessName -ieq "landlords_server") {
      Write-Host "[landlords] stop stale server pid=$($listener.ProcessId) name=$($listener.ProcessName)"
      Stop-Process -Id $listener.ProcessId -Force
      continue
    }

    $occupiedPorts = $group.Group | Select-Object -ExpandProperty Port -Unique
    $processLabel = if ($listener.ProcessName) { $listener.ProcessName } else { "unknown process" }
    $processPath = if ($listener.Path) { $listener.Path } else { "<path unavailable>" }
    throw "Port conflict on $($occupiedPorts -join ', '): process $processLabel (PID $($listener.ProcessId), $processPath) is already listening. Stop it first or update landlords.env / LANDLORDS_PORT / LANDLORDS_WS_PORT."
  }

  if ($listeners.Count -gt 0) {
    Wait-PortsReleased -Ports $Ports
  }
}

$serverExe = Resolve-ServerExe

if (-not $env:LANDLORDS_BOT_BACKEND) {
  $env:LANDLORDS_BOT_BACKEND = "onnx"
}
if (-not $env:LANDLORDS_DOUZERO_ONNX_DIR_EASY) {
  $env:LANDLORDS_DOUZERO_ONNX_DIR_EASY = "backend/ai_models/onnx/douzero_ADP"
}
if (-not $env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL) {
  $env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL = "backend/ai_models/onnx/sl"
}
if (-not $env:LANDLORDS_DOUZERO_ONNX_DIR_HARD) {
  $env:LANDLORDS_DOUZERO_ONNX_DIR_HARD = "backend/ai_models/onnx/douzero_WP"
}
if (-not $env:LANDLORDS_DOUZERO_ONNX_DIR) {
  $env:LANDLORDS_DOUZERO_ONNX_DIR = $env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL
}
if (-not $env:LANDLORDS_HINT_BOT_DIFFICULTY) {
  $env:LANDLORDS_HINT_BOT_DIFFICULTY = "hard"
}
if (-not $env:LANDLORDS_MANAGED_BOT_DIFFICULTY) {
  $env:LANDLORDS_MANAGED_BOT_DIFFICULTY = "hard"
}

$onnxDirEasy = Resolve-RepoPath $env:LANDLORDS_DOUZERO_ONNX_DIR_EASY
$onnxDirNormal = Resolve-RepoPath $env:LANDLORDS_DOUZERO_ONNX_DIR_NORMAL
$onnxDirHard = Resolve-RepoPath $env:LANDLORDS_DOUZERO_ONNX_DIR_HARD

if (-not (Test-Path (Join-Path $onnxDirEasy "landlord.onnx"))) {
  throw "Easy ONNX model not found under: $onnxDirEasy"
}

if (-not (Test-Path (Join-Path $onnxDirNormal "landlord.onnx"))) {
  throw "Normal ONNX model not found under: $onnxDirNormal"
}

if (-not (Test-Path (Join-Path $onnxDirHard "landlord.onnx"))) {
  throw "Hard ONNX model not found under: $onnxDirHard"
}

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
Write-Host "[landlords] hint_difficulty=$env:LANDLORDS_HINT_BOT_DIFFICULTY"
Write-Host "[landlords] managed_difficulty=$env:LANDLORDS_MANAGED_BOT_DIFFICULTY"
Write-Host "[landlords] tcp_port=$tcpPort"
Write-Host "[landlords] ws_port=$wsPort"
Write-Host "[landlords] log_level=$env:LANDLORDS_LOG_LEVEL"
& $serverExe
