param(
  [switch]$BuildOnly
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSCommandPath

function Import-LandlordsEnv {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [switch]$OverwriteExisting
  )

  $envPath = Join-Path $RepoRoot "landlords.env"
  if (-not (Test-Path $envPath)) {
    throw "landlords.env not found: $envPath"
  }

  foreach ($rawLine in Get-Content $envPath) {
    $line = $rawLine.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
      continue
    }

    $separatorIndex = $line.IndexOf("=")
    if ($separatorIndex -lt 1) {
      continue
    }

    $name = $line.Substring(0, $separatorIndex).Trim()
    if ($name -notmatch "^[A-Za-z_][A-Za-z0-9_]*$") {
      continue
    }

    $value = $line.Substring($separatorIndex + 1)
    if ($value.Length -ge 2) {
      $first = $value[0]
      $last = $value[$value.Length - 1]
      if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
        $value = $value.Substring(1, $value.Length - 2)
      }
    }
    $existing = [System.Environment]::GetEnvironmentVariable($name, "Process")
    if (-not $OverwriteExisting -and -not [string]::IsNullOrWhiteSpace($existing)) {
      continue
    }

    [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
  }
}

function Get-LandlordsEnvValue {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$DefaultValue = ""
  )

  $value = [System.Environment]::GetEnvironmentVariable($Name, "Process")
  if ([string]::IsNullOrWhiteSpace($value)) {
    return $DefaultValue
  }
  return $value
}

function Get-LandlordsFlutterDartDefineArgs {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Keys
  )

  $args = @()
  foreach ($key in $Keys) {
    $value = [System.Environment]::GetEnvironmentVariable($key, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) {
      continue
    }
    $args += "--dart-define=$key=$value"
  }
  return $args
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

Import-LandlordsEnv -RepoRoot $root -OverwriteExisting
Write-Host "[landlords-frontend-windows] loaded landlords.env"

$webRoot = Join-Path $root "build\web"
$serverScript = Join-Path $root "tool\web_public_server.dart"
$hostName = Get-LandlordsEnvValue -Name "LANDLORDS_WEB_HOST" -DefaultValue "0.0.0.0"
$port = [int](Get-LandlordsEnvValue -Name "LANDLORDS_WEB_PORT" -DefaultValue "23000")
$backendWs = Get-LandlordsEnvValue -Name "LANDLORDS_BACKEND_WS_PROXY" -DefaultValue "ws://127.0.0.1:23002/ws"
$dartDefineArgs = Get-LandlordsFlutterDartDefineArgs -Keys @(
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

Push-Location $root
try {
  Write-Host "[landlords-frontend-windows] building Flutter Web release"
  $flutterArgs = @("build", "web", "--release", "--no-wasm-dry-run") + $dartDefineArgs
  & flutter @flutterArgs
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build web failed with exit code $LASTEXITCODE"
  }

  if (-not (Test-Path (Join-Path $webRoot "index.html"))) {
    throw "Web build output not found under: $webRoot"
  }

  if ($BuildOnly) {
    Write-Host "[landlords-frontend-windows] build-only completed"
    exit 0
  }

  $occupied = Get-ListeningProcessInfo -Port $port
  if ($occupied) {
    $processLabel = if ($occupied.ProcessName) {
      "$($occupied.ProcessName) (PID $($occupied.ProcessId))"
    } elseif ($occupied.ProcessId) {
      "PID $($occupied.ProcessId)"
    } else {
      "an unknown process"
    }
    throw "Port $port is already in use by $processLabel. Stop that process first or update LANDLORDS_WEB_PORT in landlords.env."
  }

  Write-Host "[landlords-frontend-windows] host=$hostName port=$port"
  Write-Host "[landlords-frontend-windows] web_root=$webRoot"
  Write-Host "[landlords-frontend-windows] proxy /ws -> $backendWs"
  & dart $serverScript --host $hostName --port $port --web-root $webRoot --backend-ws $backendWs
} finally {
  Pop-Location
}
