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
        "res://assets/settlement3d/runtime/opening_style/farm.tscn",
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
        "res://assets/settlement3d/runtime/opening_style/fir_tall.tscn",
        "res://assets/settlement3d/runtime/opening_style/spruce.tscn",
        "res://assets/settlement3d/runtime/opening_style/broadleaf.tscn",
        "res://assets/settlement3d/runtime/opening_style/oak.tscn",
        "res://assets/settlement3d/runtime/opening_style/birch.tscn",
        "res://assets/settlement3d/runtime/opening_style/fir_lod.tscn",
        "res://assets/settlement3d/runtime/opening_style/broadleaf_lod.tscn",
    ],
    "ROCKS": [
        "res://assets/settlement3d/runtime/opening_style/rocks.tscn",
        "res://assets/settlement3d/runtime/nature/Rock_1_A_Color1.gltf",
        "res://assets/settlement3d/runtime/nature/Rock_1_B_Color1.gltf",
        "res://assets/settlement3d/runtime/nature/Rock_2_A_Color1.gltf",
        "res://assets/settlement3d/runtime/nature/Rock_2_B_Color1.gltf",
    ],
    "UNDERSTORY": [
        "res://assets/settlement3d/runtime/opening_style/bush.tscn",
    ],
    "GRASS": [
        "res://assets/settlement3d/runtime/opening_style/grass.tscn",
    ],
    "FLOWERS": [
        "res://assets/settlement3d/runtime/opening_style/flowers.tscn",
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


RUNTIME_ROOT = "res://assets/settlement3d/runtime"
MODEL_EXT = (".tscn", ".res", ".gltf", ".glb")
LITERAL_MODEL_RE = re.compile(r'res://[A-Za-z0-9_./-]+\.(?:tscn|res|gltf|glb)')
ROOT_CONCAT_RE = re.compile(
    r'(?:ROOT|Catalog\.ROOT)\s*\+\s*["\']([^"\']+\.(?:tscn|res|gltf|glb))["\']'
)
FRAGMENT_RE = re.compile(
    r'["\'](/(?:opening_style|buildings|nature|farm|characters|resources|tools|animations)/'
    r'[^"\']+\.(?:tscn|res|gltf|glb))["\']'
)
NAME_LIST_RE = re.compile(r'\[\s*((?:"[a-z][a-z0-9_]*"(?:\s*,\s*)+)+"[a-z][a-z0-9_]*")\s*\]')
OPENING_CONCAT_RE = re.compile(r'opening_style/"\s*\+')


def companion_res(path):
    """PackedScene .tscn files keep their mesh in a sibling .res."""
    if path.endswith(".tscn"):
        return path[:-5] + ".res"
    return ""


def scan_code_model_paths():
    """GFX-E: catch models loaded by string, not only the stale catalog lists.

    export_filter=\"resources\" does not follow load(\"res://...\") string
    paths, so birch / fir_tall / farm were missing from #61 while the audit
    still printed MISSING 0.
    """
    paths = set()
    src_root = Path("src")
    if not src_root.exists():
        return []
    for gd_path in src_root.rglob("*.gd"):
        text = gd_path.read_text(encoding="utf-8")
        for match in LITERAL_MODEL_RE.findall(text):
            if match.startswith("res://assets/settlement3d/"):
                paths.add(match)
        for frag in ROOT_CONCAT_RE.findall(text):
            paths.add(RUNTIME_ROOT + (frag if frag.startswith("/") else "/" + frag))
        for frag in FRAGMENT_RE.findall(text):
            paths.add(RUNTIME_ROOT + frag)
        if OPENING_CONCAT_RE.search(text):
            for name in re.findall(r'"([a-z][a-z0-9_]*)"', text):
                candidate = f"{RUNTIME_ROOT}/opening_style/{name}.tscn"
                if file_exists(candidate):
                    paths.add(candidate)
        for name_blob in NAME_LIST_RE.findall(text):
            for name in re.findall(r'"([a-z][a-z0-9_]*)"', name_blob):
                candidate = f"{RUNTIME_ROOT}/opening_style/{name}.tscn"
                if file_exists(candidate):
                    paths.add(candidate)
    resolved = set()
    for path in paths:
        resolved.add(path)
        sibling = companion_res(path)
        if sibling and file_exists(sibling):
            resolved.add(sibling)
    return sorted(resolved)


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
        script_dir = os.path.dirname(script.replace("res://", ""))
        with open(script.replace("res://", ""), "r") as f:
            for target in re.findall(r'preload\(\s*"([^"]+)"\s*\)', f.read()):
                if target.startswith("res://"):
                    targets.add(target)
                elif target.endswith((".gd", ".tscn", ".png", ".wav", ".ogg")):
                    resolved = os.path.normpath(os.path.join(script_dir, target)).replace("\\", "/")
                    targets.add("res://" + resolved)
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
    code_models = scan_code_model_paths()
    print(f"Code-referenced model paths: {len(code_models)}")
    runtime_paths = sorted(set(runtime_paths) | set(preloads) | set(code_models))

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
