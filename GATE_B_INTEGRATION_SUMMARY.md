# Gate B Integration Summary
**Date**: 2026-11-04 19:13 UTC
**Branch**: `cursor/visual-rescue-gate-b-a12a`
**Commit**: e108c77938a607a5e9e0aa940a43331b81dea3f3
**PR**: https://github.com/BrotherHelmer/SnS-Isometric/pull/96 (DRAFT)

## Status: READY FOR PURPLE'S CAPTURES

Code integration complete. Awaiting Godot execution for proof captures.

## Quick Start (Purple)

```bash
cd ~/sns-3d  # or wherever SnS-Isometric is
git fetch origin
git checkout cursor/visual-rescue-gate-b-a12a
git pull

# Verify GLBs present
ls -lh assets/settlement3d/runtime/gate_b_nordic/

# BASELINE capture (no --gate-b-enable flag)
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 \
  --dio-game-shot artifacts/gate-b/baseline_day.png

# GATE B capture (WITH --gate-b-enable flag)
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --gate-b-enable \
  --dio-game-shot artifacts/gate-b/gate_b_day.png

# Repeat for dusk and night
```

See `GATE_B_NOTES.md` in repo root for complete instructions.

## What Was Done

### 1. Blender Kit Integration
- Extracted Purple's `sns-gate-b-kit.tgz` to `tools/blender/gate-b-kit/`
- Copied 6 GLBs to `assets/settlement3d/runtime/gate_b_nordic/`:
  - `sns_town_hall.glb` (846 tri)
  - `sns_house.glb` (472 tri)
  - `sns_lumber_camp.glb` (484 tri)
  - `sns_tree_pine.glb` (62 tri)
  - `sns_tree_round.glb` (80 tri)
  - `sns_path_strip.glb` (32 tri)
- All CC0 procedural (Blender 4.2.3 LTS scripts), 0 DKK

### 2. Code Integration
- Created `gate_b_config.gd`: Static utility for `--gate-b-enable` flag detection
- Modified `production_building_view_3d.gd`:
  - Check Gate B models first when flag enabled
  - Fallback to `DioramaBuildings.build()` if no flag or model missing
  - No changes to simulation/save/HUD/input/camera
- Created reference scripts (not used but kept):
  - `production_diorama_buildings_gate_b.gd` (improved procedural builders)
  - `production_asset_catalog_gate_b.gd` (catalog wrapper)

### 3. Documentation
- `GATE_B_NOTES.md`: Complete capture instructions + L3 checklist
- `artifacts/gate-b/INTEGRATION_SUMMARY.md`: This file

## How It Works

**Without `--gate-b-enable` flag**:
- `production_building_view_3d.gd` line ~247: `gate_b_path` returns empty string
- Falls through to existing: `DioramaBuildings.build(building_type, entity_id)`
- Baseline presentation unchanged

**With `--gate-b-enable` flag**:
- `GateBConfig.get_building_model("TOWN_HALL")` returns `"res://assets/.../sns_town_hall.glb"`
- Loads GLB as PackedScene, instantiates, scales per `ScaleProfile.building_scale()`
- Only works for Town Hall, House, Lumber Camp (Gate B proof scope)
- Other buildings fall back to baseline

## Files Changed

```
M  src/GodotClient3D/Scripts/production_building_view_3d.gd  (13 lines: Gate B check + fallback)
A  src/GodotClient3D/Scripts/gate_b_config.gd                (83 lines: flag utility)
A  src/GodotClient3D/Scripts/production_asset_catalog_gate_b.gd  (107 lines: reference)
A  src/GodotClient3D/Scripts/production_diorama_buildings_gate_b.gd  (377 lines: reference)
A  assets/settlement3d/runtime/gate_b_nordic/*.glb           (6 GLBs)
A  tools/blender/gate-b-kit/*                                (kit source + scripts)
A  GATE_B_NOTES.md                                           (240 lines: instructions)
```

## Proof Scope

**In scope**: Town Hall, House, Lumber Camp only

**Out of scope** (fall back to baseline):
- Sawmill, Farm, Bakery, Storehouse, Quarry, Watchtower, Barracks
- Wall, Lumen Pillar, Claimant Outpost, Wyrd Harvester/Refiner
- Castle (barracks upgrade of Town Hall)
- Trees (GLBs present but nature MultiMesh not yet wired)
- Path tiles (GLB present but RoadView not yet wired)

## Expected Results

### Baseline (no flag)
- Current `production_diorama_buildings.gd` procedural meshes
- Town Hall: stone keep with terra/red roofs
- House: cottage variants, current roof angles
- Lumber Camp: current timber shed
- Same as develop/3d @ 368bbbcb presentation

### Gate B (with flag)
- Nordic kit GLBs
- Town Hall: Light stone #b8b4a8, 4 towers, red conical caps #c23b2a
- House: Steep red gable, timber/stone, storybook proportions
- Lumber Camp: Open-front thatch shed, visible log piles
- Trees: Mid-green (if wired), not dark blobs
- Warmer, more saturated palette overall

### Pass Criteria
- Black ≥7/10 vs `helmer_target_look_2026-10-18.jpg` (bottom)
- Helmer ≥8/10 professional indie art-directed
- Substantially better than baseline
- Distinct silhouettes (not "same procedural look")

## Captures Needed (Purple)

All captures: seed 424242, lumber fixture, 1280x720, identical camera, day/dusk/night

1. **Baseline** (no `--gate-b-enable`):
   - `artifacts/gate-b/baseline_day.png`
   - `artifacts/gate-b/baseline_dusk.png` (may need manual phase_time)
   - `artifacts/gate-b/baseline_night.png` (use `--dio-night`)

2. **Gate B** (with `--gate-b-enable`):
   - `artifacts/gate-b/gate_b_day.png`
   - `artifacts/gate-b/gate_b_dusk.png`
   - `artifacts/gate-b/gate_b_night.png`

3. **Metadata**:
   - `artifacts/gate-b/NOTES.txt` (camera pos/rot, seed, resolution, Godot version)

## C-Only Control

**Skipped** unless Helmer/Black specifically requests. C-only was defined as "material/lighting/palette pass on existing meshes" for comparison. Gate B primary (A+C Blender kit) is the deliverable.

## Known Limitations

1. **Trees**: GLBs present but world_view nature MultiMesh not yet wired to use them
2. **Path tiles**: GLB present but RoadView uses procedural, not yet wired
3. **Dusk capture**: May need to manually inject `sim.phase_time` value between day/night
4. **Material tuning**: GLBs use flat Blender Principled materials, no Godot shader ramps yet

## Next Steps

1. Purple runs captures (see `GATE_B_NOTES.md`)
2. Copy PNGs to `artifacts/gate-b/`
3. Commit + push captures to branch
4. Visual review vs `helmer_target_look`
5. If promising → send to Black for scoring
6. If Black ≥7/10 and Helmer ≥8/10:
   - Convert PR #96 to ready (remove draft)
   - Run full test suite
   - Perf check (draws/tri/FPS)
   - Merge to develop/3d

## Contact

- PR: https://github.com/BrotherHelmer/SnS-Isometric/pull/96
- Branch: `cursor/visual-rescue-gate-b-a12a`
- Questions: Ping agent or Purple

---

**Agent**: Cloud agent on 2026-11-04
**Blockers**: Godot execution (not available on cloud VM)
**Outcome**: Code integration COMPLETE, awaiting Purple's Godot captures
