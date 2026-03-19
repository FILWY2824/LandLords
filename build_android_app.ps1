$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:DART_SUPPRESS_ANALYTICS = "true"

$root = Split-Path -Parent $PSCommandPath
$wsUrl = if ($env:LANDLORDS_WS_URL) {
  $env:LANDLORDS_WS_URL
} elseif ($env:LANDLORDS_MOBILE_WS_URL) {
  $env:LANDLORDS_MOBILE_WS_URL
} else {
  ""
}

Push-Location $root
try {
  if ([string]::IsNullOrWhiteSpace($wsUrl)) {
    Write-Warning "LANDLORDS_WS_URL 未设置，Android 将回退到默认本地地址 ws://10.0.2.2:23002/ws。"
    Write-Warning "如果你要连 Cloudflare，请先设置：`$env:LANDLORDS_WS_URL = 'wss://你的域名/ws'"
    & flutter build apk --debug
  } else {
    Write-Host "[landlords-build] flutter build apk --debug --dart-define=LANDLORDS_WS_URL=$wsUrl"
    & flutter build apk --debug --dart-define="LANDLORDS_WS_URL=$wsUrl"
  }

  if ($LASTEXITCODE -ne 0) {
    throw "flutter build apk --debug failed with exit code $LASTEXITCODE"
  }

  $output = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"
  if (-not (Test-Path $output)) {
    throw "Android debug output not found: $output"
  }

  Write-Host "[landlords-build] output=$output"
} finally {
  Pop-Location
}
