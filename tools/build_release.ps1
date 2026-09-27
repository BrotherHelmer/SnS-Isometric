param([switch]$SkipVerification)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $workspaceRoot '.tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
$template = Join-Path $workspaceRoot '.tools/godot-4.7/templates/windows_release_x86_64.exe'
if (-not (Test-Path -LiteralPath $engine) -or -not (Test-Path -LiteralPath $template)) { throw 'Install the pinned Godot 4.7 stable engine and Windows templates in .tools/godot-4.7. See docs/BUILD_AND_TEST.md.' }
$version = '0.2.0-playtest.13'
$releaseDirectory = Join-Path $workspaceRoot "dist/ShardAndSovereign_$version"
$evidenceDirectory = Join-Path $workspaceRoot 'artifacts/release_candidate'
New-Item -ItemType Directory -Force -Path $releaseDirectory, $evidenceDirectory | Out-Null
$oldAppData = $env:APPDATA
function Assert-GodotLog([string]$Path) {
    $errors = @(Get-Content -LiteralPath $Path | Where-Object { $_ -match '^(SCRIPT ERROR:|ERROR:)' -and $_ -notmatch '^ERROR: Failed to read the root certificate store\.' })
    if ($errors.Count) { $errors | Write-Output; throw "Godot reported errors in $Path" }
}
function Invoke-Godot([string[]]$GodotArgs, [string]$ConsoleLog, [string]$FailMessage) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $engine @GodotArgs *> $ConsoleLog
    $code = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($code -ne 0) { throw $FailMessage }
}
try {
    $env:APPDATA = "$evidenceDirectory/build_user"
    New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
    Invoke-Godot @('--headless','--path',$workspaceRoot,'--editor','--import','--log-file',"$evidenceDirectory/import.log") "$evidenceDirectory/import.console.txt" 'Godot import failed.'
    Assert-GodotLog "$evidenceDirectory/import.console.txt"
    if (-not $SkipVerification) { & "$PSScriptRoot/verify_release.ps1" }
    Invoke-Godot @('--headless','--path',$workspaceRoot,'--script','res://tools/write_engine_notices.gd') "$evidenceDirectory/notices.console.txt" 'Engine license extraction failed.'
    Assert-GodotLog "$evidenceDirectory/notices.console.txt"
    Invoke-Godot @('--headless','--path',$workspaceRoot,'--export-release','Windows Desktop',"$releaseDirectory/ShardAndSovereign.exe",'--log-file',"$evidenceDirectory/export.log") "$evidenceDirectory/export.console.txt" 'Godot export failed. Read artifacts/release_candidate/export.log.'
    Assert-GodotLog "$evidenceDirectory/export.console.txt"
} finally { $env:APPDATA = $oldAppData }
$revision = (& git -C $workspaceRoot rev-parse HEAD).Trim()
$sourceRoots = @('src/GodotClient/Scripts', 'src/GodotClient3D', 'assets/settlement3d/runtime', 'assets/settlement/audio')
$sourceFiles = @('project.godot', 'export_presets.cfg')
foreach ($sourceRoot in $sourceRoots) {
    $sourceFiles += Get-ChildItem -LiteralPath (Join-Path $workspaceRoot $sourceRoot) -Recurse -File | Where-Object { $_.Extension -notin @('.uid', '.import') } | ForEach-Object { $_.FullName.Substring($workspaceRoot.Length).TrimStart('\').Replace('\', '/') }
}
$manifest = [ordered]@{version=$version; built_utc=[DateTime]::UtcNow.ToString('o'); git_revision=$revision; working_tree_dirty=([bool](& git -C $workspaceRoot status --porcelain)); engine_version=(& $engine --version | Select-Object -First 1); engine_sha256=(Get-FileHash -LiteralPath $engine).Hash; template_sha256=(Get-FileHash -LiteralPath $template).Hash; sources=@(); outputs=@()}
foreach ($sourceFile in ($sourceFiles | Sort-Object -Unique)) { $manifest.sources += @{path=$sourceFile;sha256=(Get-FileHash -LiteralPath (Join-Path $workspaceRoot $sourceFile)).Hash} }
foreach ($file in Get-ChildItem -LiteralPath $releaseDirectory -File | Where-Object { $_.Extension -in @('.exe', '.pck') }) { $manifest.outputs += @{path=$file.Name;sha256=(Get-FileHash -LiteralPath $file.FullName).Hash;bytes=$file.Length} }
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$releaseDirectory/build_manifest.json"
foreach ($doc in @('PLAYTEST_GUIDE.md','PLAYTEST_KNOWN_ISSUES.md')) { Copy-Item -LiteralPath "$workspaceRoot/docs/$doc" -Destination $releaseDirectory }
Copy-Item -LiteralPath "$workspaceRoot/docs/THIRD_PARTY_NOTICES.txt", "$evidenceDirectory/GODOT_COPYRIGHT.txt" -Destination $releaseDirectory
Copy-Item -LiteralPath "$workspaceRoot/docs/art/ASSET_LEDGER.md" -Destination "$releaseDirectory/ASSET_LEDGER.md"
Copy-Item -LiteralPath "$workspaceRoot/docs/art/AUDIO_LICENSE_LEDGER.md" -Destination "$releaseDirectory/AUDIO_LICENSE_LEDGER.md"
if (Test-Path "$workspaceRoot/docs/art/OPENING_STYLE_MODELS.md") { Copy-Item -LiteralPath "$workspaceRoot/docs/art/OPENING_STYLE_MODELS.md" -Destination $releaseDirectory }
Compress-Archive -Path "$releaseDirectory/*" -DestinationPath "$releaseDirectory.zip" -Force
Write-Output "RELEASE_BUILD PASS $releaseDirectory"
