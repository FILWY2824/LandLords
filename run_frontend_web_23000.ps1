$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSCommandPath
$envLoader = Join-Path $root "tool\Load-LandlordsEnv.ps1"
if (Test-Path $envLoader) {
  . $envLoader
  $loadedEnv = Import-LandlordsEnv -RepoRoot $root
  if ($loadedEnv) {
    Write-Host "[landlords-web] loaded landlords.env"
  }
}

$webRoot = Join-Path $root "build\web"
$serverScript = Join-Path $root "tool\web_public_server.dart"
$hostName = if ($env:LANDLORDS_WEB_HOST) { $env:LANDLORDS_WEB_HOST } else { "0.0.0.0" }
$port = if ($env:LANDLORDS_WEB_PORT) { $env:LANDLORDS_WEB_PORT } else { "23000" }
$backendWs = if ($env:LANDLORDS_BACKEND_WS_PROXY) { $env:LANDLORDS_BACKEND_WS_PROXY } else { "ws://127.0.0.1:23002/ws" }
$dartDefineKeys = @(
  "LANDLORDS_WS_URL",
  "LANDLORDS_TCP_HOST",
  "LANDLORDS_TCP_PORT",
  "LANDLORDS_MOBILE_WS_URL",
  "LANDLORDS_GITHUB_REPO",
  "LANDLORDS_DOWNLOAD_URL"
)

if (-not (Test-Path $serverScript)) {
  throw "Web public server script not found: $serverScript"
}

function Get-ListeningProcessInfo {
  param(
    [Parameter(Mandatory = $true)]
    [int]$Port
  )

  try {
    $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    $portInUse = $listeners | Where-Object { $_.Port -eq $Port }
    if (-not $portInUse) {
      return $null
    }
  } catch {
    $portInUse = $true
  }

  $line = netstat -ano -p tcp |
    Where-Object { $_ -match "LISTENING" } |
    ForEach-Object { $_.ToString() } |
    Where-Object {
      $tokens = ($_ -replace '^\s+', '') -split '\s+'
      if ($tokens.Count -lt 5 -or $tokens[0] -ne "TCP" -or $tokens[3] -ne "LISTENING") {
        return $false
      }
      if ($tokens[1] -notmatch ":(\d+)$") {
        return $false
      }
      return [int]$Matches[1] -eq $Port
    } |
    Select-Object -First 1
  if (-not $line) {
    return [pscustomobject]@{
      Port = $Port
      ProcessId = $null
      ProcessName = $null
      Path = $null
    }
  }

  $tokens = ($line -replace '^\s+', '') -split '\s+'
  $listenerPid = [int]$tokens[-1]
  $process = Get-Process -Id $listenerPid -ErrorAction SilentlyContinue
  return [pscustomobject]@{
    Port = $Port
    ProcessId = $listenerPid
    ProcessName = if ($process) { $process.ProcessName } else { $null }
    Path = if ($process) { $process.Path } else { $null }
  }
}

Push-Location $root
try {
  $occupied = Get-ListeningProcessInfo -Port ([int]$port)
  if ($occupied) {
    $processLabel = if ($occupied.ProcessName) {
      "$($occupied.ProcessName) (PID $($occupied.ProcessId))"
    } elseif ($occupied.ProcessId) {
      "PID $($occupied.ProcessId)"
    } else {
      "an unknown process"
    }
    throw @"
Port $port is already in use by $processLabel.

If that is your existing web service, you can keep using it directly.
If you want to restart it, stop the process first:
  Stop-Process -Id $($occupied.ProcessId) -Force

Or choose another port before starting:
  `$env:LANDLORDS_WEB_PORT = "23001"
  powershell -NoProfile -ExecutionPolicy Bypass -File .\run_frontend_web_23000.ps1

Or set it in landlords.env:
  LANDLORDS_WEB_PORT=23001
"@
  }

  Write-Host "[landlords-web] building Flutter Web release..."
  $flutterArgs = @("build", "web", "--release", "--no-wasm-dry-run")
  foreach ($key in $dartDefineKeys) {
    $value = [System.Environment]::GetEnvironmentVariable($key, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) {
      continue
    }
    Write-Host "[landlords-web] dart-define $key=$value"
    $flutterArgs += "--dart-define=$key=$value"
  }

  & flutter @flutterArgs
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build web failed with exit code $LASTEXITCODE"
  }

  if (-not (Test-Path (Join-Path $webRoot "index.html"))) {
    throw "Web build output not found under: $webRoot"
  }

  Write-Host "[landlords-web] host=$hostName port=$port"
  Write-Host "[landlords-web] web_root=$webRoot"
  Write-Host "[landlords-web] proxy /ws -> $backendWs"
  & dart $serverScript --host $hostName --port $port --web-root $webRoot --backend-ws $backendWs
} finally {
  Pop-Location
}
