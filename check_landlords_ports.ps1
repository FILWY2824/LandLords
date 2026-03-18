$ErrorActionPreference = "Stop"

$ports = @(23000, 23001, 23002)

function Get-PortListeners {
  param(
    [Parameter(Mandatory = $true)]
    [int[]]$Ports
  )

  $portSet = @{}
  foreach ($port in $Ports) {
    $portSet[$port] = $true
  }

  $lines = netstat -ano -p tcp | Select-String -Pattern 'LISTENING'
  $results = @()

  foreach ($match in $lines) {
    $line = ($match.Line -replace '^\s+', '')
    if (-not $line) {
      continue
    }
    $tokens = $line -split '\s+'
    if ($tokens.Length -lt 5) {
      continue
    }

    $protocol = $tokens[0]
    $localAddress = $tokens[1]
    $state = $tokens[3]
    $processIdText = $tokens[4]

    $portText = $null
    if ($localAddress -match '^\[(.+)\]:(\d+)$') {
      $portText = $Matches[2]
    } elseif ($localAddress -match '^(.+):(\d+)$') {
      $portText = $Matches[2]
    }

    if (-not $portText) {
      continue
    }

    $port = [int]$portText
    if (-not $portSet.ContainsKey($port)) {
      continue
    }

    $processId = [int]$processIdText
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

    $results += [pscustomobject]@{
      Port = $port
      Protocol = $protocol
      LocalAddress = $localAddress
      State = $state
      ProcessId = $processId
      ProcessName = if ($process) { $process.ProcessName } else { '-' }
      Path = if ($process -and $process.Path) { $process.Path } else { '-' }
    }
  }

  return $results | Sort-Object Port, ProcessId
}

function Write-PortSummary {
  param(
    [Parameter(Mandatory = $true)]
    [int[]]$Ports,
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object[]]$Listeners = @()
  )

  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Write-Host "[landlords-ports] $timestamp"
  Write-Host ""

  foreach ($port in $Ports) {
    $entries = @($Listeners | Where-Object { $_.Port -eq $port })
    if ($entries.Count -eq 0) {
      Write-Host ("[{0}] FREE" -f $port) -ForegroundColor Green
      Write-Host ""
      continue
    }

    Write-Host ("[{0}] IN USE" -f $port) -ForegroundColor Yellow
    foreach ($entry in $entries) {
      Write-Host ("  PID   : {0}" -f $entry.ProcessId)
      Write-Host ("  Name  : {0}" -f $entry.ProcessName)
      Write-Host ("  Local : {0}" -f $entry.LocalAddress)
      Write-Host ("  State : {0}" -f $entry.State)
      Write-Host ("  Path  : {0}" -f $entry.Path)
      Write-Host ""
    }
  }
}

$listeners = Get-PortListeners -Ports $ports
Write-PortSummary -Ports $ports -Listeners $listeners
