#!/usr/bin/env python3
"""Audit export_presets.cfg against runtime asset paths."""

import os
import re
from pathlib import Path

# Asset catalog paths (from production_asset_catalog.gd all_runtime_paths())
ASSET_CATALOG_GROUPS = {
    "CHARACTERS": [
        "res://assets/settlement3d/runtime/characters/Rogue.glb",
        "res://assets/settlement3d/runtime/characters/Farmer_B.glb",
        "res://assets/settlement3d/runtime/characters/Rogue_Hooded.glb",
        "res://assets/settlement3d/runtime/characters/Farmer_A.glb",
        "res://assets/settlement3d/runtime/characters/Barbarian.glb",
        "res://assets/settlement3d/runtime/characters/Knight.glb",
        "res://assets/settlement3d/runtime/characters/Ranger.glb",
        "res://assets/settlement3d/runtime/characters/Mage.glb",
    ],
    "ANIMATION_LIBRARIES": [
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_CombatMelee.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_CombatRanged.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_General.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_MovementAdvanced.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_MovementBasic.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_Simulation.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_Special.glb",
        "res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_Tools.glb",
    ],
    "BUILDINGS": [
        "res://assets/settlement3d/runtime/opening_style/town_hall.tscn",
        "res://assets/settlement3d/runtime/opening_style/castle.tscn",
        "res://assets/settlement3d/runtime/opening_style/house.tscn",
        "res://assets/settlement3d/runtime/opening_style/lumber_camp.tscn",
        "res://assets/settlement3d/runtime/opening_style/quarry.tscn",
        "res://assets/settlement3d/runtime/opening_style/bakery.tscn",
        "res://assets/settlement3d/runtime/opening_style/storehouse.tscn",
        "res://assets/settlement3d/runtime/opening_style/watchtower.tscn",
        "res://assets/settlement3d/runtime/opening_style/barracks.tscn",
        "res://assets/settlement3d/runtime/buildings/building_bridge_A.gltf",
        "res://assets/settlement3d/runtime/opening_style/lumen_pillar.tscn",
        "res://assets/settlement3d/runtime/opening_style/enemy_camp.tscn",
    ],
    "TOOLS": [
        "res://assets/settlement3d/runtime/tools/axe.gltf",
        "res://assets/settlement3d/runtime/tools/pickaxe.gltf",
        "res://assets/settlement3d/runtime/tools/hammer.gltf",
        "res://assets/settlement3d/runtime/tools/saw.gltf",
        "res://assets/settlement3d/runtime/tools/shovel.gltf",
    ],
    "CARGO": [
        "res://assets/settlement3d/runtime/resources/Wood_Log_A.gltf",
        "res://assets/settlement3d/runtime/resources/Wood_Plank_A.gltf",
        "res://assets/settlement3d/runtime/resources/Stone_Chunks_Small.gltf",
        "res://assets/settlement3d/runtime/opening_style/wheat.tscn",
        "res://assets/settlement3d/runtime/buildings/crate_A_small.gltf",
        "res://assets/settlement3d/runtime/resources/Iron_Bar.gltf",
    ],
    "WORKYARD_PROPS": [
        "res://assets/settlement3d/runtime/opening_style/wheat.tscn",
        "res://assets/settlement3d/runtime/opening_style/lantern.tscn",
        "res://assets/settlement3d/runtime/opening_style/fence.tscn",
        "res://assets/settlement3d/runtime/opening_style/cart.tscn",
        "res://assets/settlement3d/runtime/resources/Wood_Log_Stack.gltf",
        "res://assets/settlement3d/runtime/resources/Wood_Planks_Stack_Small.gltf",
        "res://assets/settlement3d/runtime/resources/Stone_Bricks_Stack_Small.gltf",
        "res://assets/settlement3d/runtime/buildings/barrel.gltf",
        "res://assets/settlement3d/runtime/buildings/crate_A_small.gltf",
        "res://assets/settlement3d/runtime/buildings/crate_long_A.gltf",
        "res://assets/settlement3d/runtime/farm/pitchfork.gltf",
        "res://assets/settlement3d/runtime/farm/dirt_plot.gltf",
        "res://assets/settlement3d/runtime/farm/wheelbarrow.gltf",
        "res://assets/settlement3d/runtime/tools/axe.gltf",
        "res://assets/settlement3d/runtime/buildings/weaponrack.gltf",
        "res://assets/settlement3d/runtime/buildings/target.gltf",
    ],
    "TREES": [
        "res://assets/settlement3d/runtime/opening_style/fir.tscn",
        "res://assets/settlement3d/runtime/opening_style/broadleaf.tscn",
    ],
    "ROCKS": [
        "res://assets/settlement3d/runtime/opening_style/rocks.tscn",
    ],
    "UNDERSTORY": [
        "res://assets/settlement3d/runtime/opening_style/bush.tscn",
        "res://assets/settlement3d/runtime/opening_style/grass.tscn",
    ],
    "GRASS": [
        "res://assets/settlement3d/runtime/opening_style/grass.tscn",
    ],
}

# Audio paths from production_audio_director.gd
AUDIO_STEM_PATHS = [
    "res://assets/settlement/audio/presentation/bgm_settlement_loop.ogg",
    "res://assets/settlement/audio/presentation/score_settlement_activity.wav",
    "res://assets/settlement/audio/presentation/score_dusk_tension.wav",
    "res://assets/settlement/audio/presentation/score_night_percussion.wav",
    "res://assets/settlement/audio/presentation/score_metal_combat.wav",
    "res://assets/settlement/audio/presentation/ambient_world.wav",
    "res://assets/settlement/audio/presentation/wyrd_drone.wav",
    "res://assets/settlement/audio/presentation/lumen_hum.wav",
]

AUDIO_CUE_PATHS = [
    "res://assets/settlement/audio/presentation/ui_click.wav",
    "res://assets/settlement/audio/presentation/nightfall_sting.wav",
    "res://assets/settlement/audio/presentation/dawn_release.wav",
    "res://assets/settlement/audio/presentation/victory_motif.wav",
    "res://assets/settlement/audio/presentation/defeat_motif.wav",
    "res://assets/settlement/audio/presentation/reckoning_pulse.wav",
    "res://assets/settlement/audio/presentation/night_scream.wav",
    "res://assets/settlement/audio/enemy.wav",
    "res://assets/settlement/audio/night.wav",
    "res://assets/settlement/audio/attack.wav",
    "res://assets/settlement/audio/tower.wav",
    "res://assets/settlement/audio/build_start.wav",
    "res://assets/settlement/audio/build_complete.wav",
    "res://assets/settlement/audio/soldier.wav",
    "res://assets/settlement/audio/farm_animal.wav",
    "res://assets/settlement/audio/farm_ambient.wav",
    "res://assets/settlement/audio/barracks_ready.wav",
    "res://assets/settlement/audio/settler_arrive_worker.wav",
    "res://assets/settlement/audio/settler_arrive_soldier.wav",
    "res://assets/settlement/audio/settler_arrive_generic.wav",
    "res://assets/settlement/audio/monster_kill_cheer.wav",
]

AUDIO_WORK_PATHS = [
    "res://assets/settlement/audio/presentation/work_chop.wav",
    "res://assets/settlement/audio/saw.wav",
    "res://assets/settlement/audio/presentation/work_hammer.wav",
]


def get_all_runtime_paths():
    """Get all unique runtime paths from asset catalog and audio director."""
    paths = set()
    for group_paths in ASSET_CATALOG_GROUPS.values():
        paths.update(group_paths)
    paths.update(AUDIO_STEM_PATHS)
    paths.update(AUDIO_CUE_PATHS)
    paths.update(AUDIO_WORK_PATHS)
    return sorted(paths)


def parse_export_files(export_presets_path):
    """Parse export_files from export_presets.cfg."""
    with open(export_presets_path, 'r') as f:
        content = f.read()
    
    # Find export_files line
    match = re.search(r'export_files=PackedStringArray\((.*?)\)', content, re.DOTALL)
    if not match:
        return []
    
    files_str = match.group(1)
    # Extract quoted strings
    files = re.findall(r'"([^"]+)"', files_str)
    return files


def file_exists(res_path):
    """Check if a res:// path exists on disk."""
    local_path = res_path.replace("res://", "")
    return os.path.exists(local_path)


def preload_targets(export_files):
    """T-SNS-UI Look lift: preload("res://...") targets of exported scripts.

    With export_filter="resources" Godot does not follow a .gd script's
    preload() calls as dependencies, so every preloaded file must be listed in
    export_files itself (a missing one only shows up as a parse error in the
    packaged build)."""
    targets = set()
    for script in export_files:
        if not script.endswith(".gd") or not file_exists(script):
            continue
        with open(script.replace("res://", ""), "r") as f:
            for target in re.findall(r'preload\(\s*"(res://[^"]+)"\s*\)', f.read()):
                targets.add(target)
    return sorted(targets)


def main():
    repo_root = Path(__file__).parent.parent
    os.chdir(repo_root)
    
    print("\n=== EXPORT PACKING AUDIT ===\n")
    
    # Get runtime paths
    runtime_paths = get_all_runtime_paths()
    print(f"Total runtime paths: {len(runtime_paths)}")
    
    # Parse export_presets.cfg
    export_files = parse_export_files("export_presets.cfg")
    print(f"Export files count: {len(export_files)}")
    
    preloads = preload_targets(export_files)
    print(f"Preloads in exported scripts: {len(preloads)}")
    runtime_paths = sorted(set(runtime_paths) | set(preloads))

    # Find missing paths
    export_set = set(export_files)
    missing = []
    exists_but_missing = []
    
    for path in runtime_paths:
        if path not in export_set:
            missing.append(path)
            if file_exists(path):
                exists_but_missing.append(path)
    
    print(f"\n⚠ MISSING FROM EXPORT: {len(missing)} paths")
    
    if exists_but_missing:
        print(f"\n🔴 FILES THAT EXIST ON DISK BUT ARE NOT IN EXPORT_FILES ({len(exists_but_missing)}):\n")
        for path in exists_but_missing:
            print(f"  - {path}")
    
    not_on_disk = [p for p in missing if not file_exists(p)]
    if not_on_disk:
        print(f"\n⚠ Referenced but don't exist on disk ({len(not_on_disk)}):\n")
        for path in not_on_disk:
            print(f"  - {path}")
    
    print("\n=== AUDIT COMPLETE ===")
    print(f"Exit code: {1 if exists_but_missing else 0}\n")
    
    return 1 if exists_but_missing else 0


if __name__ == "__main__":
    exit(main())
