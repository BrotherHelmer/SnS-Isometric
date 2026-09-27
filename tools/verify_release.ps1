param([int]$TimeoutSeconds = 180)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $workspaceRoot '.tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
$outputRoot = Join-Path $workspaceRoot 'artifacts/release_candidate'
$tests = @('release_save_safety', 'release_logistics_safety', 'release_session_safety', 'release_outpost_assault', 'release_presentation_regressions', 'opening_style_models', 'settlement_style_capture', 'phase4_2_parse_smoke', 'godot_rebuild_smoke', 'godot_rivalry_smoke', 'phase8_bakery_haul', 'phase4_wyrdfall_smoke', 'phase4_full_run_harness', 'phase4_2_human_playtest_rescue', 'phase6_presence', 'phase7_review_evidence', 'phase5_start_menu_layout', 'phase5_settlement_speak', 'phase3_ui_interaction_smoke', 'phase3_2_real_playthrough')
New-Item -ItemType Directory -Force -Path "$outputRoot/logs", "$outputRoot/test_users" | Out-Null
$oldAppData = $env:APPDATA
$results = @()
try {
    foreach ($testName in $tests) {
        $env:APPDATA = "$outputRoot/test_users/$testName"
        New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
        $stdout = "$outputRoot/logs/$testName.stdout.txt"
        $stderr = "$outputRoot/logs/$testName.stderr.txt"
        $arguments = @('--headless', '--path', $workspaceRoot, '--log-file', "$outputRoot/logs/$testName.log", '--script', "res://tests/$testName.gd")
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $engine
        $psi.Arguments = ($arguments -join ' ')
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $psi.WorkingDirectory = $workspaceRoot
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) { $process.Kill(); $process.WaitForExit() }
        $stdoutContent = $process.StandardOutput.ReadToEnd()
        $stderrContent = $process.StandardError.ReadToEnd()
        $stdoutContent | Set-Content -LiteralPath $stdout
        $stderrContent | Set-Content -LiteralPath $stderr
        $output = $stdoutContent + $stderrContent
        # This exact Windows certificate message was reproduced only under the
        # restricted execution environment; unrestricted verification is clean.
        $errors = @($output -split "`n" | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:|FAIL[: ]|.*_FAIL)' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
        $passed = -not $timedOut -and $process.ExitCode -eq 0 -and $output -match '(?m)^\w+ PASS' -and $errors.Count -eq 0
        $results += [PSCustomObject]@{test=$testName; passed=$passed; exit_code=$process.ExitCode; timed_out=$timedOut; errors=$errors}
        Write-Output "$testName passed=$passed exit=$($process.ExitCode)"
        if (-not $passed) { $errors | Select-Object -First 8 | Write-Output }
    }
} finally { $env:APPDATA = $oldAppData }
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$outputRoot/verification.json"
if (@($results | Where-Object { -not $_.passed }).Count -gt 0) { throw 'Release verification failed. See artifacts/release_candidate/verification.json.' }
Write-Output 'RELEASE_VERIFICATION PASS'
