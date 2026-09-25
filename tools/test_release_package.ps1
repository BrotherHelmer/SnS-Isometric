param([int]$SoakSeconds = 4, [switch]$Rendered, [string]$ValidationSave = '')
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $workspaceRoot 'dist/ShardAndSovereign_0.2.0-playtest.1'
$mode = if ($Rendered) { 'rendered' } else { 'headless' }
$validationDirectory = Join-Path $env:TEMP "SnS_Playtest_Validation_$mode"
New-Item -ItemType Directory -Force -Path $validationDirectory | Out-Null
Copy-Item -Path "$sourceDirectory/*" -Destination $validationDirectory -Force
$oldAppData = $env:APPDATA
try {
    $env:APPDATA = "$validationDirectory/user"
    New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
    $arguments = @('--log-file', "$validationDirectory/validation.log")
    if (-not $Rendered) { $arguments += '--headless' }
    $arguments += @('--', '--verify-release', "--soak-seconds=$SoakSeconds")
    if ($Rendered) { $arguments += '--capture' }
    if ($ValidationSave) {
        Copy-Item -LiteralPath $ValidationSave -Destination "$validationDirectory/developed_realm.json"
        $arguments += "--validation-save=$validationDirectory/developed_realm.json"
    }
    $process = Start-Process -FilePath "$validationDirectory/ShardAndSovereign.exe" -WorkingDirectory $validationDirectory -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput "$validationDirectory/stdout.txt" -RedirectStandardError "$validationDirectory/stderr.txt" -PassThru
    Write-Output "PACKAGE_TEST pid=$($process.Id) directory=$validationDirectory duration=$SoakSeconds"
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $memorySamples = @()
    $nextSample = 0
    while (-not $process.WaitForExit(1000)) {
        if ($watch.Elapsed.TotalSeconds -ge $SoakSeconds + 60) { $process.Kill(); throw 'Packaged game timed out.' }
        if ($watch.Elapsed.TotalSeconds -ge $nextSample) {
            $process.Refresh()
            $memorySamples += @{seconds=[Math]::Round($watch.Elapsed.TotalSeconds, 1);working_set_bytes=$process.WorkingSet64;private_bytes=$process.PrivateMemorySize64}
            $nextSample += 30
        }
    }
    $output = (Get-Content "$validationDirectory/stdout.txt" -Raw) + (Get-Content "$validationDirectory/stderr.txt" -Raw)
    $errors = @($output -split "`n" | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:|FAIL )' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
    $evidenceDirectory = Join-Path $workspaceRoot "artifacts/release_candidate/package_$mode"
    New-Item -ItemType Directory -Force -Path $evidenceDirectory | Out-Null
    $memorySamples | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$evidenceDirectory/process_memory.json"
    Copy-Item -Path "$validationDirectory/*.txt", "$validationDirectory/validation.log" -Destination $evidenceDirectory
    $userDirectory = "$validationDirectory/user/ShardAndSovereign/Playtest"
    Copy-Item -Path "$userDirectory/release_*" -Destination $evidenceDirectory -ErrorAction SilentlyContinue
    if ($process.ExitCode -ne 0 -or $errors.Count -gt 0 -or $output -notmatch 'RELEASE_PACKAGE_PROBE PASS') { $errors | Write-Output; throw 'Packaged build validation failed.' }
    Write-Output "PACKAGE_VALIDATION PASS $evidenceDirectory"
} finally { $env:APPDATA = $oldAppData }
