# Gate B RETRY — Implementation Notes
**Date**: 2026-11-04 19:29 UTC  
**Branch**: `cursor/visual-rescue-gate-b-a12a`  
**PR**: https://github.com/BrotherHelmer/SnS-Isometric/pull/96 (DRAFT, no merge)

## STOP ORDERS (Binding)

**Helmer GO Gate B RETRY via Black**: STOP iterating procedural cubes/cones kit. That was NOT approved A+C.

### New Orders

1. ✅ Keep PR #96 DRAFT, no merge, 0 DKK, Nordic Diorama LOCKED
2. ✅ Scope: **Town Hall ONLY** (no house/lumber until TH beats baseline)
3. ✅ Remove/disable procedural `sns_town_hall.glb` cube-kit as primary
4. ⏳ Wait for real Blender **kitbash** GLB from Purple's `sns-gate-b-retry.tgz`
5. ✅ Wire ONLY Town Hall to kitbash under `--gate-b-retry` flag
6. ✅ Implement C-only challenger under `--gate-b-control` flag
7. ⏳ Purple will re-capture on box with seed 424242 lumber fixture

## What Changed (RETRY pivot)

### 1. Dual Flag Infrastructure

**File**: `src/GodotClient3D/Scripts/gate_b_config.gd`

```gdscript
# PRIMARY: Kitbash path (awaiting tarball)
--gate-b-retry
  → Checks RETRY_MODELS["TOWN_HALL"]
  → Path: "res://assets/.../gate_b_retry/sns_townhall_kitbash.glb"
  → Mesh replacement with detailed KayKit civic_keep base
  
# CHALLENGER: C-only control
--gate-b-control
  → Builds baseline mesh (DioramaBuildings.build())
  → Applies Nordic palette remap to materials
  → No mesh change, material/lighting only
  
# BASELINE: No flag
  → production_diorama_buildings.gd unchanged
  
# DISABLED: Legacy --gate-b-enable
  → Hard disabled (LEGACY_DISABLED = true)
  → Procedural cube kit rejected
```

### 2. Building View Integration

**File**: `src/GodotClient3D/Scripts/production_building_view_3d.gd`

```gdscript
func _create_completed_model():
  # Path A: RETRY kitbash (when tarball arrives)
  if --gate-b-retry and building_type == "TOWN_HALL":
    → Load sns_townhall_kitbash.glb
    → Print "GATE_B_RETRY: Loaded kitbash"
    → Return (skip baseline)
  
  # Path B: C-only control (material remap)
  if --gate-b-control and building_type == "TOWN_HALL":
    → Build baseline DioramaBuildings mesh
    → Call _apply_gate_b_control_materials()
    → Print "GATE_B_CONTROL: Applied material remap"
    → Return
  
  # Path C: BASELINE (unchanged)
  → DioramaBuildings.build() as before
```

### 3. C-Only Material Remap

**New function**: `_apply_gate_b_control_materials(root: Node3D)`

- Walks all MeshInstance3D children
- Remaps materials to Nordic palette:
  - Stone: #b8b4a8 (warm light stone)
  - Roof: #c23b2a (terracotta red)
  - Thatch: #d9a84e (golden yellow)
  - Timber: #6b4423 (dark brown)
  - Plaster: #e8e0cc (warm cream)
- Heuristic color matching (hue/sat/value)
- Preserves textures if present
- No mesh changes

## Expected Kitbash Spec (from Purple)

**Source**: Existing KayKit `civic_keep.gltf` or similar detailed mesh

**Method**:
- Import to Blender 4.2.3 LTS
- Modify/combine geometry (preserve detail)
- Apply Nordic materials (Principled BSDF with palette colors)
- Scale-normalize to ~3.0×3.7×2.8 m footprint (Town Hall)
- Export glTF +Y up as `sns_townhall_kitbash.glb`

**Expected output**:
```
sns-gate-b-retry.tgz containing:
  glb/sns_townhall_kitbash.glb
  README.md (build notes)
  LICENCE.md (CC0 or owned)
```

**NOT**: Procedural cubes/cones (rejected)

## Integration Steps (When Tarball Arrives)

```bash
# 1. Extract tarball
cd /agent/repos/SnS-Isometric
tar -xzf /path/to/sns-gate-b-retry.tgz -C assets/settlement3d/runtime/gate_b_retry/

# 2. Verify GLB
ls -lh assets/settlement3d/runtime/gate_b_retry/sns_townhall_kitbash.glb

# 3. Test RETRY path
~/godot/4.7/godot --resolution 1280x720 --path . \
  --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --gate-b-retry \
  --dio-game-shot artifacts/gate-b/retry_day.png

# 4. Test C-only control
~/godot/4.7/godot --resolution 1280x720 --path . \
  --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 --gate-b-control \
  --dio-game-shot artifacts/gate-b/control_day.png

# 5. Baseline (no flag)
~/godot/4.7/godot --resolution 1280x720 --path . \
  --script res://tests/godot_diorama_capture.gd -- \
  --autostart --fixture=lumber --seed=424242 \
  --dio-game-shot artifacts/gate-b/baseline_day.png
```

## Capture Matrix (Purple)

All captures: seed 424242, lumber fixture, identical camera, 1280x720

| Variant | Flag | Expected Result | File |
|---------|------|-----------------|------|
| Baseline | (none) | Current procedural DioramaBuildings TH | `baseline_day.png` |
| RETRY kitbash | `--gate-b-retry` | Detailed KayKit civic_keep + Nordic materials | `retry_day.png` |
| C-only control | `--gate-b-control` | Same baseline mesh + Nordic palette remap | `control_day.png` |

Repeat for night (`--dio-night`).

## Pass Criteria

**RETRY kitbash must clearly beat baseline** for Town Hall before expanding to house/lumber.

Black scores:
- Baseline: Current score (known)
- RETRY kitbash: Must be ≥8/10 vs helmer_target_look
- C-only control: Reference only (tests how much is materials vs geometry)

Helmer approves RETRY ≥8/10 → expand to house/lumber.  
If RETRY ≤ baseline → reassess strategy.

## Files Changed (RETRY pivot)

```
M src/GodotClient3D/Scripts/gate_b_config.gd         (dual flags, legacy disabled)
M src/GodotClient3D/Scripts/production_building_view_3d.gd  (dual paths + C-only remap)
A assets/settlement3d/runtime/gate_b_retry/README.md
A GATE_B_RETRY_NOTES.md (this file)
```

Legacy procedural kit at `gate_b_nordic/*.glb` still on disk but disabled (LEGACY_DISABLED = true).

## Current Status

✅ **Dual flag infrastructure complete**  
✅ **C-only material remap implemented**  
✅ **Town Hall scope enforced**  
✅ **Legacy procedural kit disabled**  
⏳ **Awaiting Purple's `sns-gate-b-retry.tgz`**  

Next: Purple sends tarball → extract → test flags → capture comparison.

---

**Branch**: `cursor/visual-rescue-gate-b-a12a`  
**Commits**: (pending, will add after this pivot)  
**PR**: https://github.com/BrotherHelmer/SnS-Isometric/pull/96 (DRAFT)
