#Requires -Version 5.1
<#
.SYNOPSIS
  Capture a PNG screenshot from a connected Android device via adb.

.DESCRIPTION
  Requires adb on PATH and at least one device in "device" state.
  If no device / unauthorized, exit non-zero so the Agent can ask the user.

.PARAMETER OutFile
  Full path of the PNG to write (directories are created if missing).

.PARAMETER Serial
  Optional adb device serial (-s).

.EXAMPLE
  .\capture_play_screenshots.ps1 -OutFile D:\materials\play_screenshots\01_home.png
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$OutFile,

    [string]$Serial
)

$ErrorActionPreference = "Stop"

function Invoke-Adb {
    param([string[]]$AdbArgs)
    if ($Serial) {
        & adb -s $Serial @AdbArgs
    } else {
        & adb @AdbArgs
    }
    if ($LASTEXITCODE -ne 0) {
        throw "adb failed: adb $($AdbArgs -join ' ') (exit $LASTEXITCODE)"
    }
}

$adbCmd = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbCmd) {
    Write-Error "adb not found on PATH. Install platform-tools or ask the user."
    exit 2
}

$devicesOutput = & adb devices
$ready = @()
foreach ($line in $devicesOutput) {
    if ($line -match "^\s*$" -or $line -match "List of devices") { continue }
    if ($line -match "^(\S+)\s+device\s*$") { $ready += $Matches[1] }
    if ($line -match "^(\S+)\s+unauthorized") {
        Write-Error "Device $($Matches[1]) is unauthorized. Ask the user to accept the RSA prompt."
        exit 3
    }
}

if ($ready.Count -eq 0) {
    Write-Error "No adb device in 'device' state. Connect a phone over USB (or authorized Wi-Fi adb) and ask the user if needed."
    exit 4
}

if (-not $Serial -and $ready.Count -gt 1) {
    Write-Host "Multiple devices: $($ready -join ', '). Pass -Serial explicitly."
    exit 5
}

$dir = Split-Path -Parent $OutFile
if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$remote = "/sdcard/Download/play_cap_{0}.png" -f ([guid]::NewGuid().ToString("N").Substring(0, 8))
try {
    Invoke-Adb -AdbArgs @("shell", "screencap", "-p", $remote)
    Invoke-Adb -AdbArgs @("pull", $remote, $OutFile)
} finally {
    try { Invoke-Adb -AdbArgs @("shell", "rm", "-f", $remote) } catch { }
}

if (-not (Test-Path $OutFile)) {
    Write-Error "Screenshot was not written to $OutFile"
    exit 6
}

Write-Host "Saved $OutFile"
exit 0
