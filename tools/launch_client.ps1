param(
    [ValidateSet("legacy", "3d")]
    [string]$Presentation = "3d",
    [int]$Seed = 260821,
    [switch]$Load,
    [string]$Fixture = "",
    [ValidateSet("recommended", "scalable_low")]
    [string]$Quality = "recommended"
)

$ErrorActionPreference = "Stop"
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $workspaceRoot ".tools\godot-4.7\Godot_v4.7-stable_win64.exe"
if (-not (Test-Path -LiteralPath $godot -PathType Leaf)) {
    throw "Godot executable not found at $godot"
}

if ($Presentation -eq "legacy") {
    & $godot --path $workspaceRoot --rendering-method gl_compatibility
    exit $LASTEXITCODE
}

$arguments = @(
    "--path", $workspaceRoot,
    "--rendering-method", "forward_plus",
    "res://src/GodotClient3D/Scenes/production_3d.tscn",
    "--", "--seed=$Seed", "--quality=$Quality"
)
if ($Load) { $arguments += "--load" }
if ($Fixture -ne "") { $arguments += "--fixture=$Fixture" }
& $godot @arguments
exit $LASTEXITCODE
