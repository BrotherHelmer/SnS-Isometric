$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $workspaceRoot '.tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
$evidence = Join-Path $workspaceRoot 'artifacts/release_candidate'
$oldAppData = $env:APPDATA
$results = @()
try {
    $env:APPDATA = "$evidence/process_user"
    New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
    foreach ($mode in @('prepare', 'relaunch')) {
        $arguments = @('--headless', '--path', $workspaceRoot, '--script', 'res://tests/release_process_persistence.gd')
        if ($mode -eq 'prepare') { $arguments += @('--', '--prepare') }
        $stdout = "$evidence/process_$mode.stdout.txt"
        $stderr = "$evidence/process_$mode.stderr.txt"
        $quotedArguments = $arguments | ForEach-Object { '"' + $_ + '"' }
        $process = Start-Process -FilePath $engine -ArgumentList $quotedArguments -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        $timedOut = -not $process.WaitForExit(180000)
        if ($timedOut) { $process.Kill(); $process.WaitForExit() }
        $output = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
        $errors = @($output -split "`n" | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:|FAIL )' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
        $passed = -not $timedOut -and $process.ExitCode -eq 0 -and $errors.Count -eq 0 -and $output -match "RELEASE_PROCESS_PERSISTENCE PASS mode=$mode"
        $results += @{mode=$mode;passed=$passed;exit_code=$process.ExitCode;timed_out=$timedOut;errors=$errors}
        $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$evidence/process_persistence/verification.json"
        if (-not $passed) { throw "Process persistence $mode failed. Read $stdout and $stderr" }
        Write-Output "PROCESS_PERSISTENCE $mode PASS"
    }
} finally { $env:APPDATA = $oldAppData }
