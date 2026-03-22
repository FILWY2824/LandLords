function Import-LandlordsEnv {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [string]$FileName = "landlords.env",

    [switch]$OverwriteExisting
  )

  $envPath = Join-Path $RepoRoot $FileName
  if (-not (Test-Path $envPath)) {
    return $false
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
      if (($first -eq '"' -and $last -eq '"') -or
          ($first -eq "'" -and $last -eq "'")) {
        $value = $value.Substring(1, $value.Length - 2)
      }
    }

    $existing = [System.Environment]::GetEnvironmentVariable($name, "Process")
    if (-not $OverwriteExisting -and -not [string]::IsNullOrEmpty($existing)) {
      continue
    }

    [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
  }

  return $true
}
