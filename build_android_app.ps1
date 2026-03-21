param(
  [ValidateSet("debug", "release")]
  [string]$Mode = "debug",

  [string]$WsUrl = "",

  [switch]$SplitPerAbi
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:DART_SUPPRESS_ANALYTICS = "true"

$root = Split-Path -Parent $PSCommandPath

if ([string]::IsNullOrWhiteSpace($WsUrl)) {
  if ($env:LANDLORDS_WS_URL) {
    $WsUrl = $env:LANDLORDS_WS_URL
  } elseif ($env:LANDLORDS_MOBILE_WS_URL) {
    $WsUrl = $env:LANDLORDS_MOBILE_WS_URL
  }
}

$flutterArgs = @("build", "apk", "--$Mode")
if ($SplitPerAbi) {
  $flutterArgs += "--split-per-abi"
}
if (-not [string]::IsNullOrWhiteSpace($WsUrl)) {
  $flutterArgs += "--dart-define=LANDLORDS_WS_URL=$WsUrl"
}

Push-Location $root
try {
  if ([string]::IsNullOrWhiteSpace($WsUrl)) {
    Write-Warning "LANDLORDS_WS_URL is not set. Android will use the app default WebSocket URL."
    Write-Warning "If you need a remote server, set it first, for example:"
    Write-Warning '$env:LANDLORDS_WS_URL = "wss://your-domain/ws"'
  }

  Write-Host "[landlords-build] flutter $($flutterArgs -join ' ')"
  & flutter @flutterArgs

  if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk --$Mode failed with exit code $LASTEXITCODE"
  }

  $outputDir = Join-Path $root "build\app\outputs\flutter-apk"

  if ($SplitPerAbi) {
    if (-not (Test-Path $outputDir)) {
      throw "Android output directory not found: $outputDir"
    }

    $artifacts = Get-ChildItem $outputDir -Filter "*.apk" |
      Where-Object { $_.Name -like "app-*-$Mode.apk" }

    if (-not $artifacts) {
      throw "No split APK artifacts found in: $outputDir"
    }

    foreach ($artifact in $artifacts) {
      Write-Host "[landlords-build] output=$($artifact.FullName)"
    }
  } else {
    $apkName = if ($Mode -eq "release") { "app-release.apk" } else { "app-debug.apk" }
    $output = Join-Path $outputDir $apkName
    if (-not (Test-Path $output)) {
      throw "Android output not found: $output"
    }
    Write-Host "[landlords-build] output=$output"
  }

  if ($Mode -eq "release") {
    Write-Warning "Current Android release build uses the debug signing config. Configure a real keystore before publishing."
  }
} finally {
  Pop-Location
}
