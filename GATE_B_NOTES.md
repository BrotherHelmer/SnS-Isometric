# Gate B Visual Rescue — Implementation Notes
Branch: `cursor/visual-rescue-gate-b-a12a` from develop/3d @ `368bbbcb`
Date: 2026-11-04
Budget: 0 DKK (CC0 procedural Blender kit)

## STATUS: Awaiting in-engine captures on Purple's machine

Code integration COMPLETE. Godot execution needed for proof captures.

## What was done

1. **Blender Kit Integration** (tools/blender/gate-b-kit/)
   - Extracted Purple's Nordic kit: sns_town_hall.glb (846 tri), sns_house.glb (472 tri), sns_lumber_camp.glb (484 tri), sns_tree_pine.glb (62 tri), sns_tree_round.glb (80 tri), sns_path_strip.glb (32 tri)
   - Copied GLBs to `assets/settlement3d/runtime/gate_b_nordic/`
   - CC0 procedural, no third-party assets

2. **Catalog Integration with Fallback**
   - Created `src/GodotClient3D/Scripts/gate_b_config.gd` (static utility)
   - Modified `src/GodotClient3D/Scripts/production_building_view_3d.gd` to check Gate B models first, fallback to baseline DioramaBuildings
   - Command line flag: `--gate-b-enable` switches to Gate B models
   - No flag = baseline production_diorama_buildings (existing behavior)

3. **Supporting Scripts**
   - `src/GodotClient3D/Scripts/production_diorama_buildings_gate_b.gd` — improved procedural buildings (NOT USED, kept for reference)
   - `src/GodotClient3D/Scripts/production_asset_catalog_gate_b.gd` — catalog wrapper (NOT USED, kept for reference)
   - Actual implementation uses direct GLB loading via gate_b_config.gd

## What needs doing (Purple on box)

### Prerequisites
- Godot 4.7 at ~/godot/4.7/godot or in PATH
- Branch: `cursor/visual-rescue-gate-b-a12a`
- Blender kit already in `tools/blender/gate-b-kit/` (committed)
- GLBs already in `assets/settlement3d/runtime/gate_b_nordic/` (committed)

### Capture Plan

All captures: same seed (424242), lumber fixture (Town Hall + Lumber Camp + houses visible), identical camera position, 1280x720, day/dusk/night.

#### 1. BASELINE (current develop/3d presentation @ 368bbbcb)
```bash
cd ~/sns-3d  # or wherever SnS-Isometric repo is
git checkout cursor/visual-rescue-gate-b-a12a

# Day capture (baseline, no --gate-b-enable)
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 \
  --dio-game-shot artifacts/gate-b/baseline_day.png

# Dusk (hold at dusk phase)
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 \
  --dio-game-shot artifacts/gate-b/baseline_dusk.png
  # Note: May need custom dusk time injection in capture script

# Night
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --dio-night \
  --dio-game-shot artifacts/gate-b/baseline_night.png
```

**IMPORTANT**: Baseline captures must be taken WITHOUT `--gate-b-enable` flag to show current production_diorama_buildings state.

#### 2. GATE B PRIMARY (A+C: Nordic kit GLBs)
```bash
# Day capture (WITH --gate-b-enable)
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --gate-b-enable \
  --dio-game-shot artifacts/gate-b/gate_b_day.png

# Dusk
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --gate-b-enable \
  --dio-game-shot artifacts/gate-b/gate_b_dusk.png

# Night
~/godot/4.7/godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --dio-night --gate-b-enable \
  --dio-game-shot artifacts/gate-b/gate_b_night.png
```

#### 3. C-ONLY CONTROL (material/lighting/palette pass on existing meshes)
**C-only is a control comparison ONLY** — not a separate deliverable. This tests how much improvement comes from materials vs geometry.

Option A: Quick test via manual material tweaks in editor
Option B: Create temporary material override script that applies PIPELINE.md palette to existing production_diorama_buildings output

For now: **SKIP C-only captures** unless Helmer/Black specifically requests the comparison. Gate B primary (A+C) is the main deliverable.

### Verification Commands
```bash
# Check Gate B GLBs present
ls -lh assets/settlement3d/runtime/gate_b_nordic/

# Check git status
git status
git log --oneline -3

# Test Gate B flag detection (should print "GATE_B enabled")
~/godot/4.7/godot --path . --headless --script - -- --gate-b-enable << 'EOF'
extends SceneTree
func _init():
    var cfg = load("res://src/GodotClient3D/Scripts/gate_b_config.gd")
    print(cfg.get_info())
    quit()
EOF
```

### Expected Outcomes

**Baseline captures** should show:
- Current production_diorama_buildings.gd procedural meshes
- Town Hall: stone keep with terra/red roofs (current look)
- House: cottage variants with current roof angles
- Lumber Camp: current timber shed
- Trees: current opening_style (may appear dark if not tuned)

**Gate B captures** should show:
- Nordic kit GLBs with improved silhouettes
- Town Hall: light stone (#b8b4a8) with 4 towers + red conical caps (#c23b2a)
- House: steep red gable roof, timber/stone walls, distinct from Town Hall
- Lumber Camp: open-front thatch shed with visible log piles
- Trees: mid-green pine/broadleaf (not dark blobs)
- Warmer, more saturated palette overall

**Pass criteria** (Black scores, Helmer approves):
- Gate B ≥8/10 vs helmer_target_look (bottom half of reference image)
- Substantially better than baseline
- Distinct building silhouettes (not "same procedural look")
- Warmer palette, steeper roofs, better architectural variety
- Runs in real founded game (not just offline renders)

## Files Changed Summary

### Assets (committed)
```
+ tools/blender/gate-b-kit/README.md                    (kit documentation)
+ tools/blender/gate-b-kit/LICENCE.md                   (CC0 licence)
+ tools/blender/gate-b-kit/TRIS.txt                     (triangle counts)
+ tools/blender/gate-b-kit/scripts/build_kit.py         (Blender rebuild script)
+ tools/blender/gate-b-kit/glb/sns_town_hall.glb        (846 tri)
+ tools/blender/gate-b-kit/glb/sns_house.glb            (472 tri)
+ tools/blender/gate-b-kit/glb/sns_lumber_camp.glb      (484 tri)
+ tools/blender/gate-b-kit/glb/sns_tree_pine.glb        (62 tri)
+ tools/blender/gate-b-kit/glb/sns_tree_round.glb       (80 tri)
+ tools/blender/gate-b-kit/glb/sns_path_strip.glb       (32 tri)
+ assets/settlement3d/runtime/gate_b_nordic/*.glb       (copied from kit)
```

### Scripts (committed)
```
M src/GodotClient3D/Scripts/production_building_view_3d.gd
    + Gate B model check with fallback to DioramaBuildings
    + Loads GLBs when --gate-b-enable flag present
    
+ src/GodotClient3D/Scripts/gate_b_config.gd
    Static utility for Gate B flag detection and model paths
    
+ src/GodotClient3D/Scripts/production_diorama_buildings_gate_b.gd
    (Reference only — improved procedural builders, not used in final integration)
    
+ src/GodotClient3D/Scripts/production_asset_catalog_gate_b.gd
    (Reference only — catalog wrapper, not used in final integration)
```

### Artifacts (needs Purple's captures)
```
artifacts/gate-b/baseline_day.png           (needed)
artifacts/gate-b/baseline_dusk.png          (needed)
artifacts/gate-b/baseline_night.png         (needed)
artifacts/gate-b/gate_b_day.png             (needed)
artifacts/gate-b/gate_b_dusk.png            (needed)
artifacts/gate-b/gate_b_night.png           (needed)
artifacts/gate-b/NOTES.txt                  (camera/seed/resolution)
```

## Reproduction Steps (for audit)

1. Clone SnS-Isometric
2. Checkout branch `cursor/visual-rescue-gate-b-a12a`
3. Verify GLBs present: `ls assets/settlement3d/runtime/gate_b_nordic/`
4. Run baseline captures WITHOUT --gate-b-enable
5. Run Gate B captures WITH --gate-b-enable
6. Compare captures side-by-side with helmer_target_look reference
7. Black scores Gate B captures vs target

## L3 Pre-merge Checks (if Gate B passes Helmer)

- [ ] Licence log: All GLBs CC0 (LICENCE.md in kit confirms)
- [ ] Rebuild reproducible: `blender -b -P tools/blender/gate-b-kit/scripts/build_kit.py`
- [ ] Baseline vs after: identical camera/seed confirmed in NOTES.txt
- [ ] No sim/save edits: `git diff 368bbbcb --stat` shows only presentation paths
- [ ] Catalog fallback works: running without --gate-b-enable uses baseline
- [ ] Test suite: Run existing tests, check for any new failures
- [ ] Perf: Compare draws/tri/FPS baseline vs Gate B (logged by capture script)

## Rollback Plan

Branch-only changes. No merge without Helmer GO.

To revert:
```bash
git checkout develop/3d
# Gate B changes never merged, branch deleted
```

Fallback flag (`--gate-b-enable` not passed) keeps existing production_diorama_buildings presentation.

## Known Limitations / Future Work

1. **Trees**: Gate B kit includes pine/broadleaf GLBs but world_view tree instantiation not yet wired to use them (would require nature MultiMesh modification). Trees stay baseline for now.

2. **Path tiles**: sns_path_strip.glb present but path system uses procedural RoadView. Path integration deferred.

3. **Day/dusk/night lighting**: Uses existing sim phase_time and is_night for lighting. No new light presets added (baseline lighting preserved).

4. **Dusk capture**: godot_diorama_capture.gd has --dio-night but not explicit --dio-dusk. May need to manually set sim.phase_time between captures, or add dusk flag.

5. **Other buildings**: Gate B proof scope is Town Hall, House, Lumber Camp only. Sawmill, Farm, Bakery, etc. fall back to baseline DioramaBuildings.

6. **Material tuning**: GLBs use flat Blender materials (sns_stone, sns_roof, etc.). No additional shader/ramp passes applied in Godot yet.

## Next Steps (if Gate B passes)

1. Purple runs captures on box Godot
2. Copy captures to artifacts/gate-b/
3. Purple reviews vs helmer_target_look, does informal visual check
4. If promising, send capture pack to Black for scoring
5. If Black ≥7/10 and Helmer approves ≥8/10:
   - Open real PR (not draft)
   - Add ASSET_LEDGER.md entries for Gate B GLBs
   - Run full test suite
   - Merge to develop/3d

## Contact

Questions/blockers: ping agent on Cursor or Purple directly.
Commit: [will be updated after git commit]
Branch: cursor/visual-rescue-gate-b-a12a
Base: develop/3d @ 368bbbcb
