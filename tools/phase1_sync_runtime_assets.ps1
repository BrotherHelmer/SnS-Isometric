param()

$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$vendorRoot = Join-Path $workspaceRoot "assets\Kaykit"
$labRoot = Join-Path $workspaceRoot "phase1_3d_lab"
$runtimeRoot = Join-Path $labRoot "assets\runtime"
$manifestEntries = [System.Collections.Generic.List[object]]::new()

function Convert-ToRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $normalizedBase = [IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $normalizedPath = [IO.Path]::GetFullPath($Path)
    if (-not $normalizedPath.StartsWith($normalizedBase, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the expected base: $normalizedPath"
    }
    return $normalizedPath.Substring($normalizedBase.Length)
}

function Resolve-RequiredDirectory {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "Required vendor directory was not found: $($Candidates -join ', ')"
}

function Copy-AllowlistedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$DestinationDirectory
    )
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Required allowlisted source file was not found: $Source"
    }
    New-Item -ItemType Directory -Force -Path $DestinationDirectory | Out-Null
    $destination = Join-Path $DestinationDirectory (Split-Path -Leaf $Source)
    Copy-Item -LiteralPath $Source -Destination $destination -Force
    $manifestEntries.Add([ordered]@{
        source = (Convert-ToRelativePath -Base $workspaceRoot -Path $Source).Replace('\', '/')
        runtime = (Convert-ToRelativePath -Base $labRoot -Path $destination).Replace('\', '/')
        bytes = (Get-Item -LiteralPath $destination).Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
    })
}

function Copy-AllowlistedGltf {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$DestinationDirectory
    )
    Copy-AllowlistedFile -Source $Source -DestinationDirectory $DestinationDirectory
    $sourceDirectory = Split-Path -Parent $Source
    $gltf = Get-Content -LiteralPath $Source -Raw | ConvertFrom-Json
    $dependencies = @()
    foreach ($buffer in @($gltf.buffers)) {
        if ($null -ne $buffer.uri) { $dependencies += [string]$buffer.uri }
    }
    foreach ($image in @($gltf.images)) {
        if ($null -ne $image.uri) { $dependencies += [string]$image.uri }
    }
    foreach ($dependency in $dependencies | Sort-Object -Unique) {
        if ($dependency -match '^[a-zA-Z]+:' -or $dependency.Contains('..')) {
            throw "External or traversing glTF dependency is not allowed: $dependency"
        }
        Copy-AllowlistedFile -Source (Join-Path $sourceDirectory $dependency) -DestinationDirectory $DestinationDirectory
    }
}

$animationRoot = Resolve-RequiredDirectory @(
    (Join-Path $vendorRoot "KayKit_Character_Animations_1.1\KayKit_Character_Animations_1.1"),
    (Join-Path $vendorRoot "KayKit_Character_Animations_1.1")
)
$adventurerRoot = Resolve-RequiredDirectory @((Join-Path $vendorRoot "KayKit_Adventurers_2.0_FREE"))
$mysteryRoot = Resolve-RequiredDirectory @((Join-Path $vendorRoot "KayKit_Mystery_Monthly_Series_6_(1.1)"))
$forestRoot = Resolve-RequiredDirectory @((Join-Path $vendorRoot "KayKit_Forest_Nature_Pack_1.0_FREE"))
$resourceRoot = Resolve-RequiredDirectory @((Join-Path $vendorRoot "KayKit_ResourceBits_1.0_FREE"))
$toolsRoot = Resolve-RequiredDirectory @((Join-Path $vendorRoot "KayKit_RPGToolsBits_1.0_FREE"))
$medievalRoot = Resolve-RequiredDirectory @((Join-Path $vendorRoot "KayKit_Medieval_Hexagon_Pack_1.0_FREE"))

$characterDestination = Join-Path $runtimeRoot "characters"
foreach ($character in @("Barbarian", "Knight", "Mage", "Ranger", "Rogue", "Rogue_Hooded")) {
    Copy-AllowlistedFile -Source (Join-Path $adventurerRoot "Characters\gltf\$character.glb") -DestinationDirectory $characterDestination
}
$farmerRoot = Join-Path $mysteryRoot "12 - June 2026 - Farmers"
foreach ($character in @("Farmer_A", "Farmer_B")) {
    Copy-AllowlistedFile -Source (Join-Path $farmerRoot "characters\$character.glb") -DestinationDirectory $characterDestination
}

$animationDestination = Join-Path $runtimeRoot "animations\Rig_Medium"
foreach ($library in @("CombatMelee", "CombatRanged", "General", "MovementAdvanced", "MovementBasic", "Simulation", "Special", "Tools")) {
    Copy-AllowlistedFile -Source (Join-Path $animationRoot "Animations\gltf\Rig_Medium\Rig_Medium_$library.glb") -DestinationDirectory $animationDestination
}

$natureDestination = Join-Path $runtimeRoot "nature"
foreach ($asset in @(
    "Tree_1_A_Color1", "Tree_1_B_Color1", "Tree_1_C_Color1",
    "Tree_2_A_Color1", "Tree_2_B_Color1", "Tree_2_C_Color1",
    "Tree_3_A_Color1", "Tree_3_B_Color1", "Tree_4_A_Color1", "Tree_4_B_Color1",
    "Rock_1_A_Color1", "Rock_1_B_Color1", "Rock_2_A_Color1", "Rock_2_B_Color1",
    "Bush_1_A_Color1", "Bush_1_B_Color1", "Bush_2_A_Color1", "Bush_2_B_Color1",
    "Grass_1_A_Color1", "Grass_1_B_Color1", "Grass_2_A_Color1", "Grass_2_B_Color1"
)) {
    Copy-AllowlistedGltf -Source (Join-Path $forestRoot "Assets\gltf\$asset.gltf") -DestinationDirectory $natureDestination
}

$resourceDestination = Join-Path $runtimeRoot "resources"
foreach ($asset in @(
    "Wood_Log_A", "Wood_Log_B", "Wood_Log_Stack", "Wood_Plank_A", "Wood_Planks_Stack_Small",
    "Stone_Chunks_Small", "Stone_Bricks_Stack_Small", "Iron_Bar", "Iron_Bars_Stack_Small"
)) {
    Copy-AllowlistedGltf -Source (Join-Path $resourceRoot "Assets\gltf\$asset.gltf") -DestinationDirectory $resourceDestination
}

$toolDestination = Join-Path $runtimeRoot "tools"
foreach ($asset in @("axe", "pickaxe", "hammer", "saw", "shovel")) {
    Copy-AllowlistedGltf -Source (Join-Path $toolsRoot "Assets\gltf\$asset.gltf") -DestinationDirectory $toolDestination
}

$farmDestination = Join-Path $runtimeRoot "farm"
foreach ($asset in @("pitchfork", "dirt_plot", "carrot", "lettuce", "wheelbarrow", "wheelbarrow_empty")) {
    Copy-AllowlistedGltf -Source (Join-Path $farmerRoot "assets\gltf\$asset.gltf") -DestinationDirectory $farmDestination
}

$buildingDestination = Join-Path $runtimeRoot "buildings"
$buildingSources = @(
    "buildings\green\building_castle_green.gltf",
    "buildings\green\building_barracks_green.gltf",
    "buildings\green\building_home_A_green.gltf",
    "buildings\green\building_lumbermill_green.gltf",
    "buildings\green\building_mine_green.gltf",
    "buildings\green\building_tower_A_green.gltf",
    "buildings\neutral\building_bridge_A.gltf",
    "decoration\props\barrel.gltf",
    "decoration\props\crate_A_small.gltf",
    "decoration\props\crate_long_A.gltf",
    "decoration\props\weaponrack.gltf",
    "decoration\props\target.gltf"
)
foreach ($relativeSource in $buildingSources) {
    Copy-AllowlistedGltf -Source (Join-Path $medievalRoot "Assets\gltf\$relativeSource") -DestinationDirectory $buildingDestination
}

$integrationDestination = Join-Path $labRoot "integration"
foreach ($script in @("one_shard_defs.gd", "one_shard_rivalry_tuning.gd", "one_shard_rivalry.gd", "one_shard_simulation.gd")) {
    Copy-AllowlistedFile -Source (Join-Path $workspaceRoot "src\GodotClient\Scripts\$script") -DestinationDirectory $integrationDestination
}

$artifactDirectory = Join-Path $labRoot "artifacts"
New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
$uniqueEntries = [ordered]@{}
foreach ($entry in $manifestEntries) {
    $uniqueEntries[[string]$entry.runtime] = $entry
}
$manifest = [ordered]@{
    schema = 1
    generated_utc = [DateTime]::UtcNow.ToString("o")
    policy = "Curated runtime copies only; vendor sources remain immutable. GLB is used for rigged assets and animations. Supplied glTF+BIN+texture triplets are used directly for static packs."
    files = @($uniqueEntries.Values | Sort-Object runtime)
}
$manifestPath = Join-Path $runtimeRoot "allowlist_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

# Phase 2 promotes the same curated source set into the production project.
# Generated Godot import sidecars remain project-local and are never mirrored.
$productionRuntimeRoot = Join-Path $workspaceRoot "assets\settlement3d\runtime"
foreach ($sourceFile in Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File) {
    if ($sourceFile.Extension -eq ".import" -or $sourceFile.Name -eq "allowlist_manifest.json") {
        continue
    }
    $relative = Convert-ToRelativePath -Base $runtimeRoot -Path $sourceFile.FullName
    $destination = Join-Path $productionRuntimeRoot $relative
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $destination -Force
}

$productionEntries = @()
foreach ($productionFile in Get-ChildItem -LiteralPath $productionRuntimeRoot -Recurse -File | Where-Object Name -ne "allowlist_manifest.json") {
    $productionEntries += [ordered]@{
        runtime = (Convert-ToRelativePath -Base $workspaceRoot -Path $productionFile.FullName).Replace('\', '/')
        bytes = $productionFile.Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $productionFile.FullName).Hash
    }
}
$productionManifest = [ordered]@{
    schema = 1
    generated_utc = [DateTime]::UtcNow.ToString("o")
    source_manifest = "phase1_3d_lab/assets/runtime/allowlist_manifest.json"
    policy = "Production promotion of the Phase 1 curated allowlist. Raw vendor paths are forbidden in gameplay and presentation code."
    files = @($productionEntries | Sort-Object runtime)
}
$productionManifestPath = Join-Path $productionRuntimeRoot "allowlist_manifest.json"
$productionManifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $productionManifestPath -Encoding UTF8

Write-Output "PHASE1_RUNTIME_SYNC_PASS files=$($uniqueEntries.Count) manifest=$manifestPath production_manifest=$productionManifestPath"
