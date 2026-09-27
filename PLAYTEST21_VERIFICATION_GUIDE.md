# Playtest.21 Verification Guide

**Version:** 0.2.0-playtest.21  
**Focus:** Castle morph fix + building visual identity improvements  
**Critical Wine gate:** Town Hall → Castle morph when Barracks completes

---

## P0: Castle Morph (Wine gate)

### Issue (playtest.20)
After Barracks completes and connects, Town Hall still renders as civic timber hall with cupola instead of upgrading to 4-tower stone fortress (castle.tscn).

### Root Cause
`_settlement_has_barracks()` was being called N times per frame (once per building) instead of once per frame. Additionally, the function used string comparison instead of the constant and had an overly conservative default for the 'completed' check.

### Fix
1. Cache `has_barracks` result once per frame in `capture_frame()`
2. Pass cached value to all `building_descriptor()` calls
3. Use `Defs.BUILDING_BARRACKS` constant instead of string literal "BARRACKS"
4. Change 'completed' default from `false` to `true` (defensive - if key missing, assume completed)
5. Make check more explicit with temp variables for clarity

### Verification Steps (Wine / Windows)
1. Start new game or load save with Town Hall + no Barracks
2. Build Barracks (place, deliver materials, wait for construction timer)
3. **CRITICAL:** Once Barracks construction completes (building type changes from CONSTRUCTION_SITE to BARRACKS, construction=false, completed=true):
   - Town Hall visual MUST immediately morph to Castle (4 corner towers, tall keep, stone fortress)
   - NOT the timber hall with cupola
   - Castle turrets should appear in Town Hall yard
   - Royal banner should appear on keep
4. Save game after castle morph, then load save
   - Castle visual must persist (not revert to timber hall)
5. Verify no freeze/stutter when castle morphs (freeze-guard preserved)

### What to Look For
- **PASS:** Town Hall upgrades to massive stone fortress with 4 corner towers matching `title_settlement_v1.png` reference
- **FAIL:** Town Hall stays as timber hall with cupola after Barracks completes
- **FAIL:** Game freezes or stutters when castle morphs (freeze-guard regression)
- **FAIL:** Castle reverts to timber hall on save/load

---

## P1: Grey Cylinder Removal

### Issue (playtest.20)
Grey cylindrical "silo" placeholders visible near Barracks and Outpost, looking unfinished or broken.

### Fix
Regenerated building models via `build_opening_style_models.gd` with improved identity:
- **Barracks:** Eliminated 4-sided cylinder roof, replaced with proper peaked roof + crenellations
- **Other buildings:** Improved visual identity (see below)

### Verification Steps
1. Place Barracks and inspect model
   - No grey cylinder "silo" shapes
   - Tower has peaked slate roof with visible structure
2. Place Outpost (Watchtower) and inspect
   - No grey placeholder cylinders
   - Tower has proper roof

### What to Look For
- **PASS:** All buildings use intentional, finished-looking geometry
- **FAIL:** Grey cylindrical placeholders visible near any building

---

## Building Visual Identity Improvements

### Barracks (Military Tower + Shields)
**Changes:**
- Stone fortress walls (was plaster)
- Stone posts (was wood) for solidity
- Taller tower with 15 masonry courses
- Iron arrow slits (was windows)
- Iron/slate military shields (was wood)
- Visible crenellations on tower
- Proper peaked roof (was 4-sided cylinder)
- Thicker iron fence bars

**Verify:** Barracks reads as military fortress, not cottage. Tower should be prominent with clear defensive features.

### Sawmill (Readable Blade)
**Changes:**
- Larger blade (0.52 radius, was 0.40)
- 24 segments (was 20) for smooth circle
- 12 visible teeth on blade edge

**Verify:** Circular saw blade is clearly visible and identifiable at strategic zoom. Teeth should be distinct.

### Bakery (Oven/Chimney)
**Changes:**
- Prominent stone chimney structure
- Three-tiered chimney cap
- Iron oven door/vent ring

**Verify:** Chimney is visible from strategic zoom, clearly identifies building as Bakery.

### Quarry (Hoist)
**Changes:**
- Taller crane post (3.4m from 3.0m)
- Thicker structural beams
- Visible iron cable attachment points
- Larger hoist stone block

**Verify:** Crane/hoist structure is clear and prominent. Building reads as stone quarry, not generic shed.

### Lumen Pillar (Crystal Presence)
**Changes:**
- Taller pillar (1.4m from 1.2m)
- 6 iron support beams (was 4)
- 6 glass crystal shards around middle
- Taller crystal top (0.8m from 0.6m)
- More prominent iron base ring

**Verify:** Crystal structure is prominent and magical-looking. Wyrd/magical identity is clear.

---

## Regression Checks

### Freeze-Guard (Castle Morph)
**Critical:** Castle morph must NOT cause per-frame rebuild loop (playtest.10 regression).
- Monitor framerate when Barracks completes
- No stutter or freeze during morph
- Castle should appear smoothly

### Save/Load (Castle State)
**Critical:** Castle visual must persist across save/load.
- Save after castle morph
- Close game
- Load save
- Town Hall must still render as Castle (not timber hall)

### Building Placement
- All improved buildings must place correctly
- No collision/footprint issues
- Construction sites work normally

---

## Known Limitations / Not Addressed

1. **Walls:** KayKit hybrid walls NOT redesigned (per user constraint)
2. **Command & Control icons:** ColorRect icons still weak (polish deferred, not P0)
3. **New building types:** No new buildings (Barracks already exists)
4. **Other buildings:** House, Lumber Camp, Farm, Watchtower, Road were already PASS in playtest.20

---

## Regeneration Required

After verifying code changes, building models must be regenerated:

```bash
# In Godot 4.7+ editor or headless:
godot --headless --script tools/build_opening_style_models.gd
```

This will update:
- `assets/settlement3d/runtime/opening_style/barracks.res` & `.tscn`
- `assets/settlement3d/runtime/opening_style/bakery.res` & `.tscn` (cottage variant)
- `assets/settlement3d/runtime/opening_style/lumber_camp.res` & `.tscn` (sawmill variant)
- `assets/settlement3d/runtime/opening_style/quarry.res` & `.tscn`
- `assets/settlement3d/runtime/opening_style/lumen_pillar.res` & `.tscn`

The improved generation code ensures no grey placeholder cylinders remain.

---

## Testing Priority

1. **Castle morph (Wine gate) - P0:** Must work in natural play and after save/load
2. **Grey cylinders removed - P1:** Visual polish, prevents "broken" perception
3. **Building identity - P1:** Sawmill blade, Barracks military, Bakery chimney, Quarry hoist, Lumen crystal
4. **Regression checks:** Freeze-guard, save/load, placement

---

## Success Criteria

**PASS if:**
- Town Hall → Castle morph works immediately when Barracks completes
- Castle visual persists across save/load
- No grey cylindrical placeholders visible
- Improved buildings have clear, readable identity at strategic zoom
- No freeze/stutter during castle morph
- All buildings place and construct normally

**FAIL if:**
- Castle morph doesn't happen (Town Hall stays timber hall after Barracks completes)
- Castle reverts to timber hall on load
- Grey cylinders still visible
- Game freezes when castle morphs

---

## Next Steps After Verification

If PASS:
- Tag playtest.21 for Wine distribution
- Update ROADMAP.md with playtest.21 entry
- Begin playtest.22 planning (next priority features)

If FAIL:
- Document specific failure mode (morph timing? save/load? freeze?)
- Check if `_settlement_has_barracks()` is finding completed Barracks
- Verify `has_barracks` flag reaches building view's `apply_snapshot()`
- Check if building view's change detection triggers `configure()`
