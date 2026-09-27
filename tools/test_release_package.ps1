param([int]$SoakSeconds = 4, [switch]$Rendered, [string]$ValidationSave = '')
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$sourceDirectory = Join-Path $workspaceRoot 'dist/ShardAndSovereign_0.2.0-playtest.4'
$mode = if ($Rendered) { 'rendered' } else { 'headless' }
$validationDirectory = Join-Path $env:TEMP "SnS_Playtest_Validation_$mode"
$evidenceDirectory = Join-Path $workspaceRoot "artifacts/release_candidate/package_$mode"
New-Item -ItemType Directory -Force -Path $evidenceDirectory | Out-Null
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
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "$validationDirectory/ShardAndSovereign.exe"
    $psi.Arguments = ($arguments -join ' ')
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $validationDirectory
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.Start() | Out-Null
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    Write-Output "PACKAGE_TEST pid=$($process.Id) directory=$validationDirectory duration=$SoakSeconds"
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $memorySamples = @()
    $nextSample = 0
    $timedOut = $false
    $buildManifest = Get-Content -LiteralPath "$sourceDirectory/build_manifest.json" -Raw | ConvertFrom-Json
    while (-not $process.WaitForExit(1000)) {
        if ($watch.Elapsed.TotalSeconds -ge $SoakSeconds + 60) { $process.Kill(); $process.WaitForExit(); $timedOut = $true; break }
        if ($watch.Elapsed.TotalSeconds -ge $nextSample) {
            $process.Refresh()
            $memorySamples += @{seconds=[Math]::Round($watch.Elapsed.TotalSeconds, 1);working_set_bytes=$process.WorkingSet64;private_bytes=$process.PrivateMemorySize64}
            $nextSample += 30
            $memorySamples | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$evidenceDirectory/process_memory.json"
            @{status='running';pid=$process.Id;elapsed_seconds=$watch.Elapsed.TotalSeconds;requested_seconds=$SoakSeconds;git_revision=$buildManifest.git_revision} | ConvertTo-Json | Set-Content -LiteralPath "$evidenceDirectory/package_validation.json"
        }
    }
    $stdoutContent = $stdoutTask.Result
    $stderrContent = $stderrTask.Result
    $stdoutContent | Set-Content -LiteralPath "$validationDirectory/stdout.txt"
    $stderrContent | Set-Content -LiteralPath "$validationDirectory/stderr.txt"
    $output = $stdoutContent + $stderrContent
    $errors = @($output -split "`n" | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:|FAIL )' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
    if ($timedOut) { $errors += 'Packaged game timed out.' }
    $memorySamples | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$evidenceDirectory/process_memory.json"
    Copy-Item -Path "$validationDirectory/*.txt", "$validationDirectory/validation.log" -Destination $evidenceDirectory
    $userDirectory = "$validationDirectory/user/ShardAndSovereign/Playtest"
    Copy-Item -Path "$userDirectory/release_*" -Destination $evidenceDirectory -ErrorAction SilentlyContinue
    $passed = -not $timedOut -and $process.ExitCode -eq 0 -and $errors.Count -eq 0 -and $output -match 'RELEASE_PACKAGE_PROBE PASS'
    @{status=$(if ($passed) {'passed'} else {'failed'});passed=$passed;exit_code=$process.ExitCode;timed_out=$timedOut;requested_seconds=$SoakSeconds;elapsed_seconds=$watch.Elapsed.TotalSeconds;git_revision=$buildManifest.git_revision;outputs=$buildManifest.outputs;errors=$errors} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$evidenceDirectory/package_validation.json"
    if (-not $passed) { $errors | Write-Output; throw 'Packaged build validation failed.' }
    Write-Output "PACKAGE_VALIDATION PASS $evidenceDirectory"
} finally { $env:APPDATA = $oldAppData }
