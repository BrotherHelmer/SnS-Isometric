# Gate B RETRY Assets

**Status**: Awaiting Purple's `sns-gate-b-retry.tgz`

## RETRY Orders (Binding)

Per Helmer via Black 2026-11-04 19:29 UTC:

1. **Scope**: Town Hall ONLY (no house/lumber until TH beats baseline)
2. **PRIMARY path**: Real Blender kitbash from existing KayKit `civic_keep.gltf`
   - Import existing detailed mesh (NOT procedural cubes/cones)
   - Modify/combine geometry
   - Preserve detail
   - Apply Nordic materials (#b8b4a8 stone, #c23b2a roof, etc.)
   - Scale-normalize to ~3.0×3.7×2.8 m Town Hall footprint
   - Export as `sns_townhall_kitbash.glb`
3. **CHALLENGER path**: C-only control (material remap only, no mesh swap)
4. **First procedural kit DISABLED**: `sns_town_hall.glb` from `sns-gate-b-kit.tgz` was NOT approved A+C

## Expected File

```
assets/settlement3d/runtime/gate_b_retry/
  └── sns_townhall_kitbash.glb
```

## Flags

```bash
# BASELINE (no flag)
# → production_diorama_buildings.gd procedural Town Hall

# PRIMARY: RETRY kitbash (awaiting tarball)
--gate-b-retry
# → Load sns_townhall_kitbash.glb for Town Hall
# → Mesh replacement with detailed KayKit-based geometry

# CHALLENGER: C-only control
--gate-b-control
# → Build baseline Town Hall mesh
# → Remap materials to Nordic palette (#b8b4a8 stone, #c23b2a roof, etc.)
# → No mesh change, material/lighting only
```

## Identical Camera Comparison

Purple will capture:
1. Baseline (no flag)
2. RETRY kitbash (`--gate-b-retry`)
3. C-only control (`--gate-b-control`)

All at seed 424242, lumber fixture, identical camera, day + night.

## Integration Status

- [x] Dual flag infrastructure (`gate_b_config.gd`)
- [x] Building view wiring (`production_building_view_3d.gd`)
- [x] C-only material remap function
- [x] Directory created
- [ ] Awaiting `sns-gate-b-retry.tgz` from Purple
- [ ] Extract kitbash GLB to this directory
- [ ] Capture comparison (baseline vs retry vs control)
