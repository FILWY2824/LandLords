param(
  [switch]$BuildOnly
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

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

function Resolve-LandlordsRepoPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [Parameter(Mandatory = $true)]
    [string]$PathValue
  )

  if ([string]::IsNullOrWhiteSpace($PathValue)) {
    return $PathValue
  }

  if ([System.IO.Path]::IsPathRooted($PathValue)) {
    return $PathValue
  }

  return Join-Path $RepoRoot $PathValue
}

function Test-LandlordsTruthy {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $false
  }

  switch ($Value.Trim().ToUpperInvariant()) {
    "1" { return $true }
    "TRUE" { return $true }
    "ON" { return $true }
    "YES" { return $true }
    default { return $false }
  }
}

function Set-ProcessEnvDefault {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$DefaultValue
  )

  if ([string]::IsNullOrWhiteSpace([System.Environment]::GetEnvironmentVariable($Name, "Process"))) {
    [System.Environment]::SetEnvironmentVariable($Name, $DefaultValue, "Process")
  }
}

function Assert-LandlordsPathExists {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,

    [Parameter(Mandatory = $true)]
    [string]$PathValue,

    [string]$Hint = ""
  )

  if (-not (Test-Path $PathValue)) {
    $message = "$Label not found: $PathValue"
    if (-not [string]::IsNullOrWhiteSpace($Hint)) {
      $message += "`n$Hint"
    }
    throw $message
  }
}

function Get-BackendBuildDir {
  return Resolve-LandlordsRepoPath -RepoRoot $root -PathValue (Get-LandlordsEnvValue -Name "LANDLORDS_CMAKE_BUILD_DIR" -DefaultValue "backend/server/build-vs")
}

function Get-BackendBuildConfig {
  return Get-LandlordsEnvValue -Name "LANDLORDS_CMAKE_BUILD_CONFIG" -DefaultValue "Debug"
}

function Resolve-LandlordsConfigPathOrEmpty {
  param([string]$Name)

  $value = Get-LandlordsEnvValue -Name $Name
  if ([string]::IsNullOrWhiteSpace($value)) {
    return ""
  }
  return Resolve-LandlordsRepoPath -RepoRoot $root -PathValue $value
}

function Resolve-BackendExecutable {
  $configuredExe = Get-LandlordsEnvValue -Name "LANDLORDS_SERVER_EXE"
  if (-not [string]::IsNullOrWhiteSpace($configuredExe)) {
    $resolved = Resolve-LandlordsRepoPath -RepoRoot $root -PathValue $configuredExe
    Assert-LandlordsPathExists -Label "Backend executable" -PathValue $resolved -Hint "Please check LANDLORDS_SERVER_EXE in landlords.env."
    return $resolved
  }

  $buildDir = Get-BackendBuildDir
  $buildConfig = Get-BackendBuildConfig
  $candidates = @(
    (Join-Path (Join-Path $buildDir $buildConfig) "landlords_server.exe"),
    (Join-Path $buildDir "landlords_server.exe")
  ) | Select-Object -Unique

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw "Backend executable not found after build. Checked: $($candidates -join ', ')"
}

function Get-ListeningProcessInfo {
  param(
    [Parameter(Mandatory = $true)]
    [int[]]$Ports
  )

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
      if ($tokens.Count -lt 5 -or $tokens[0] -ne "TCP" -or $tokens[3] -ne "LISTENING") {
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

  return @(
    $listeners |
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
  )
}

function Wait-PortsReleased {
  param(
    [Parameter(Mandatory = $true)]
    [int[]]$Ports,

    [int]$TimeoutMs = 5000
  )

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

function Ensure-ServerPortsAvailable {
  param(
    [Parameter(Mandatory = $true)]
    [int[]]$Ports
  )

  $listeners = Get-ListeningProcessInfo -Ports $Ports
  if ($listeners.Count -eq 0) {
    return
  }

  $listenersByProcess = $listeners | Group-Object ProcessId
  foreach ($group in $listenersByProcess) {
    $listener = $group.Group | Select-Object -First 1
    if ($listener.ProcessName -ieq "landlords_server") {
      Write-Host "[landlords-backend-windows] stop stale server pid=$($listener.ProcessId)"
      Stop-Process -Id $listener.ProcessId -Force
      continue
    }

    $occupiedPorts = $group.Group | Select-Object -ExpandProperty Port -Unique
    $processLabel = if ($listener.ProcessName) { $listener.ProcessName } else { "unknown process" }
    $processPath = if ($listener.Path) { $listener.Path } else { "<path unavailable>" }
    throw "Port conflict on $($occupiedPorts -join ', '): process $processLabel (PID $($listener.ProcessId), $processPath) is already listening. Stop it first or update LANDLORDS_PORT / LANDLORDS_WS_PORT in landlords.env."
  }

  Wait-PortsReleased -Ports $Ports
}

function Assert-OnnxModelsReady {
  $easyDir = Resolve-LandlordsRepoPath -RepoRoot $root -PathValue (Get-LandlordsEnvValue -Name "LANDLORDS_DOUZERO_ONNX_DIR_EASY" -DefaultValue "backend/ai_models/onnx/douzero_ADP")
  $normalDir = Resolve-LandlordsRepoPath -RepoRoot $root -PathValue (Get-LandlordsEnvValue -Name "LANDLORDS_DOUZERO_ONNX_DIR_NORMAL" -DefaultValue "backend/ai_models/onnx/sl")
  $hardDir = Resolve-LandlordsRepoPath -RepoRoot $root -PathValue (Get-LandlordsEnvValue -Name "LANDLORDS_DOUZERO_ONNX_DIR_HARD" -DefaultValue "backend/ai_models/onnx/douzero_WP")

  Assert-LandlordsPathExists -Label "Easy ONNX model" -PathValue (Join-Path $easyDir "landlord.onnx") -Hint "Please check LANDLORDS_DOUZERO_ONNX_DIR_EASY or regenerate the models."
  Assert-LandlordsPathExists -Label "Normal ONNX model" -PathValue (Join-Path $normalDir "landlord.onnx") -Hint "Please check LANDLORDS_DOUZERO_ONNX_DIR_NORMAL or regenerate the models."
  Assert-LandlordsPathExists -Label "Hard ONNX model" -PathValue (Join-Path $hardDir "landlord.onnx") -Hint "Please check LANDLORDS_DOUZERO_ONNX_DIR_HARD or regenerate the models."

  Set-ProcessEnvDefault -Name "LANDLORDS_DOUZERO_ONNX_DIR_EASY" -DefaultValue "backend/ai_models/onnx/douzero_ADP"
  Set-ProcessEnvDefault -Name "LANDLORDS_DOUZERO_ONNX_DIR_NORMAL" -DefaultValue "backend/ai_models/onnx/sl"
  Set-ProcessEnvDefault -Name "LANDLORDS_DOUZERO_ONNX_DIR_HARD" -DefaultValue "backend/ai_models/onnx/douzero_WP"
  Set-ProcessEnvDefault -Name "LANDLORDS_DOUZERO_ONNX_DIR" -DefaultValue (Get-LandlordsEnvValue -Name "LANDLORDS_DOUZERO_ONNX_DIR_NORMAL" -DefaultValue "backend/ai_models/onnx/sl")
}

function Configure-Backend {
  $sourceDir = Join-Path $root "backend\server"
  $buildDir = Get-BackendBuildDir
  $generator = Get-LandlordsEnvValue -Name "LANDLORDS_CMAKE_GENERATOR" -DefaultValue "Visual Studio 17 2022"
  $platform = Get-LandlordsEnvValue -Name "LANDLORDS_CMAKE_PLATFORM" -DefaultValue "x64"
  $buildType = Get-LandlordsEnvValue -Name "LANDLORDS_CMAKE_BUILD_TYPE"
  $protobufRoot = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_PROTOBUF_ROOT"
  $protobufProtoc = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE"
  $protobufInclude = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_PROTOBUF_INCLUDE_DIR"
  $protobufLibrary = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_PROTOBUF_LIBRARY"
  $libeventRoot = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_LIBEVENT_ROOT"
  $libeventCmakeDir = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_LIBEVENT_CMAKE_DIR"

  if ([string]::IsNullOrWhiteSpace($protobufRoot)) {
    throw "LANDLORDS_PROTOBUF_ROOT is empty. Please edit landlords.env and point it to your protobuf installation root."
  }
  if ([string]::IsNullOrWhiteSpace($protobufProtoc)) {
    throw "LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE is empty. Please edit landlords.env and point it to protoc.exe."
  }
  if ([string]::IsNullOrWhiteSpace($protobufInclude)) {
    throw "LANDLORDS_PROTOBUF_INCLUDE_DIR is empty. Please edit landlords.env and point it to the protobuf include directory."
  }
  if ([string]::IsNullOrWhiteSpace($protobufLibrary)) {
    throw "LANDLORDS_PROTOBUF_LIBRARY is empty. Please edit landlords.env and point it to libprotobuf.lib or libprotobufd.lib."
  }
  if ([string]::IsNullOrWhiteSpace($libeventRoot)) {
    throw "LANDLORDS_LIBEVENT_ROOT is empty. Please edit landlords.env and point it to your libevent installation root."
  }
  if ([string]::IsNullOrWhiteSpace($libeventCmakeDir)) {
    throw "LANDLORDS_LIBEVENT_CMAKE_DIR is empty. Please edit landlords.env and point it to the directory containing LibeventConfig.cmake."
  }

  Assert-LandlordsPathExists -Label "Protobuf root" -PathValue $protobufRoot -Hint "Please edit LANDLORDS_PROTOBUF_ROOT in landlords.env."
  Assert-LandlordsPathExists -Label "protoc executable" -PathValue $protobufProtoc -Hint "Please edit LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE in landlords.env."
  Assert-LandlordsPathExists -Label "protobuf include directory" -PathValue $protobufInclude -Hint "Please edit LANDLORDS_PROTOBUF_INCLUDE_DIR in landlords.env."
  Assert-LandlordsPathExists -Label "protobuf header" -PathValue (Join-Path $protobufInclude "google\protobuf\stubs\common.h") -Hint "LANDLORDS_PROTOBUF_INCLUDE_DIR should point to the include directory that contains google/protobuf/stubs/common.h."
  Assert-LandlordsPathExists -Label "protobuf library" -PathValue $protobufLibrary -Hint "Please edit LANDLORDS_PROTOBUF_LIBRARY in landlords.env."
  Assert-LandlordsPathExists -Label "libevent root" -PathValue $libeventRoot -Hint "Please edit LANDLORDS_LIBEVENT_ROOT in landlords.env."
  Assert-LandlordsPathExists -Label "libevent CMake package directory" -PathValue $libeventCmakeDir -Hint "Please edit LANDLORDS_LIBEVENT_CMAKE_DIR in landlords.env."

  $enableOnnxRuntime = Test-LandlordsTruthy (Get-LandlordsEnvValue -Name "LANDLORDS_ENABLE_ONNXRUNTIME" -DefaultValue "ON")
  if ($enableOnnxRuntime) {
    $onnxRoot = Resolve-LandlordsConfigPathOrEmpty "LANDLORDS_ONNXRUNTIME_ROOT"
    if ([string]::IsNullOrWhiteSpace($onnxRoot)) {
      throw "LANDLORDS_ONNXRUNTIME_ROOT is empty. Please edit landlords.env and point it to your ONNX Runtime SDK."
    }

    Assert-LandlordsPathExists -Label "ONNX Runtime root" -PathValue $onnxRoot -Hint "Please edit LANDLORDS_ONNXRUNTIME_ROOT in landlords.env."
    Assert-LandlordsPathExists -Label "ONNX Runtime header" -PathValue (Join-Path $onnxRoot "build\native\include\onnxruntime_cxx_api.h") -Hint "Please check whether the ONNX Runtime SDK was unpacked correctly."
    Assert-LandlordsPathExists -Label "ONNX Runtime library" -PathValue (Join-Path $onnxRoot "runtimes\win-x64\native\onnxruntime.lib") -Hint "Please check whether the Windows x64 ONNX Runtime native library exists."
  }

  $cmakeArgs = @("-S", $sourceDir, "-B", $buildDir)
  if (-not [string]::IsNullOrWhiteSpace($generator)) {
    $cmakeArgs += @("-G", $generator)
  }
  if (-not [string]::IsNullOrWhiteSpace($platform) -and $generator -like "Visual Studio*") {
    $cmakeArgs += @("-A", $platform)
  }
  if (-not [string]::IsNullOrWhiteSpace($buildType)) {
    $cmakeArgs += "-DCMAKE_BUILD_TYPE=$buildType"
  }

  function Add-CMakeCacheArg {
    param(
      [Parameter(Mandatory = $true)]
      [string]$CMakeName,

      [string]$Value = "",

      [switch]$PathLike
    )

    $resolvedValue = $Value
    if ($PathLike -and -not [string]::IsNullOrWhiteSpace($resolvedValue)) {
      $resolvedValue = Resolve-LandlordsRepoPath -RepoRoot $root -PathValue $resolvedValue
    }
    $cmakeArgs += "-D$CMakeName=$resolvedValue"
  }

  Add-CMakeCacheArg -CMakeName "LANDLORDS_ENABLE_ONNXRUNTIME" -Value $(if ($enableOnnxRuntime) { "ON" } else { "OFF" })
  foreach ($name in @(
    "LANDLORDS_PROTOBUF_ROOT",
    "LANDLORDS_PROTOBUF_PROTOC_EXECUTABLE",
    "LANDLORDS_PROTOBUF_INCLUDE_DIR",
    "LANDLORDS_PROTOBUF_LIBRARY",
    "LANDLORDS_LIBEVENT_ROOT",
    "LANDLORDS_LIBEVENT_CMAKE_DIR"
  )) {
    $pathValue = Get-LandlordsEnvValue -Name $name
    if ([string]::IsNullOrWhiteSpace($pathValue)) {
      throw "$name is empty. Please edit landlords.env before configuring the backend."
    }
    Add-CMakeCacheArg -CMakeName $name -Value $pathValue -PathLike
  }

  Add-CMakeCacheArg -CMakeName "LANDLORDS_ONNXRUNTIME_ROOT" -Value (Get-LandlordsEnvValue -Name "LANDLORDS_ONNXRUNTIME_ROOT") -PathLike
  Add-CMakeCacheArg -CMakeName "CMAKE_PREFIX_PATH" -Value (Get-LandlordsEnvValue -Name "LANDLORDS_CMAKE_PREFIX_PATH")

  Push-Location $root
  try {
    Write-Host "[landlords-backend-windows] loaded landlords.env"
    Write-Host "[landlords-backend-windows] configuring backend"
    & cmake @cmakeArgs
    if ($LASTEXITCODE -ne 0) {
      throw "cmake configure failed with exit code $LASTEXITCODE"
    }
  } finally {
    Pop-Location
  }
}

function Build-Backend {
  $buildDir = Get-BackendBuildDir
  $buildConfig = Get-BackendBuildConfig
  $cmakeArgs = @("--build", $buildDir)
  if (-not [string]::IsNullOrWhiteSpace($buildConfig)) {
    $cmakeArgs += @("--config", $buildConfig)
  }
  $cmakeArgs += @("--target", "landlords_server")

  Push-Location $root
  try {
    Write-Host "[landlords-backend-windows] building landlords_server"
    & cmake @cmakeArgs
    if ($LASTEXITCODE -ne 0) {
      throw "cmake build failed with exit code $LASTEXITCODE"
    }
  } finally {
    Pop-Location
  }
}

Import-LandlordsEnv -RepoRoot $root
Configure-Backend
Build-Backend

if ($BuildOnly) {
  Write-Host "[landlords-backend-windows] build-only completed"
  exit 0
}

Set-ProcessEnvDefault -Name "LANDLORDS_BOT_BACKEND" -DefaultValue "onnx"
Set-ProcessEnvDefault -Name "LANDLORDS_LOG_LEVEL" -DefaultValue "INFO"
Set-ProcessEnvDefault -Name "LANDLORDS_MANAGED_DELAY_MIN_MS" -DefaultValue "380"
Set-ProcessEnvDefault -Name "LANDLORDS_MANAGED_DELAY_MAX_MS" -DefaultValue "680"
Set-ProcessEnvDefault -Name "LANDLORDS_BOT_BID_DELAY_MIN_MS" -DefaultValue "260"
Set-ProcessEnvDefault -Name "LANDLORDS_BOT_BID_DELAY_MAX_MS" -DefaultValue "460"
Set-ProcessEnvDefault -Name "LANDLORDS_BOT_PLAY_DELAY_MIN_MS" -DefaultValue "320"
Set-ProcessEnvDefault -Name "LANDLORDS_BOT_PLAY_DELAY_MAX_MS" -DefaultValue "520"
Set-ProcessEnvDefault -Name "LANDLORDS_FINISH_DELAY_MS" -DefaultValue "520"
Set-ProcessEnvDefault -Name "LANDLORDS_PORT" -DefaultValue "23001"
Set-ProcessEnvDefault -Name "LANDLORDS_WS_PORT" -DefaultValue "23002"

Assert-OnnxModelsReady

$serverExe = Resolve-BackendExecutable
$tcpPort = [int](Get-LandlordsEnvValue -Name "LANDLORDS_PORT" -DefaultValue "23001")
$wsPort = [int](Get-LandlordsEnvValue -Name "LANDLORDS_WS_PORT" -DefaultValue "23002")
Ensure-ServerPortsAvailable -Ports @($tcpPort, $wsPort)

Write-Host "[landlords-backend-windows] server=$serverExe"
Write-Host "[landlords-backend-windows] tcp_port=$tcpPort"
Write-Host "[landlords-backend-windows] ws_port=$wsPort"
Write-Host "[landlords-backend-windows] log_level=$(Get-LandlordsEnvValue -Name 'LANDLORDS_LOG_LEVEL' -DefaultValue 'INFO')"
& $serverExe
