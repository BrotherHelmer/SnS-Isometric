# Playtest.19 Verification Guide

## Pre-Testing Setup

### 1. Regenerate Opening Style Models (REQUIRED)
```bash
# From project root
godot --headless --script tools/build_opening_style_models.gd
```

**Expected output**: `OPENING_MODELS PASS 20 models`  
**Changed file**: `assets/settlement3d/runtime/opening_style/town_hall.tscn`

### 2. Build Package
```powershell
.\tools\build_release.ps1
```

**Expected**: `artifacts/windows/ShardAndSovereign_0.2.0-playtest.19_windows.zip`

---

## Track A Verification: Placement & UX

### Test 1: Placement Color Legend
1. Start New Realm (seed 260821)
2. Open BUILD palette → select **House**
3. **CHECK**: Placement panel bottom shows: `House · GREEN = valid · YELLOW = needs clearing · RED = blocked · R rotates · click to place · right-click cancels`
4. Move ghost over valid grass → **CHECK**: Green footprint
5. Move ghost over trees → **CHECK**: Yellow footprint
6. Move ghost over Town Hall → **CHECK**: Red footprint

**Pass if**: All three colors display correctly with legend text visible.

### Test 2: Actionable Error Messages
1. Continue from Test 1
2. Try to place House far from roads (e.g., tile 20,20)
3. **CHECK**: Message reads: `INVALID · No road access. Extend roads from Town Hall first, then place buildings beside connected roads.`
   - NOT the old: "Must touch your connected road network. Extend roads..."
4. Select **Wall** building
5. Try to place wall away from any Watchtower
6. **CHECK**: Message reads: `INVALID · Walls need a Watchtower anchor. Build Watchtower first, then drag walls from it.`
   - NOT the old: "Build a Watchtower first, then hold and drag walls from it."
7. Zoom camera to edge of revealed area
8. Try to place House just beyond fog
9. **CHECK**: Message reads: `INVALID · Unrevealed terrain. Build closer to existing structures to scout ahead, or wait for workers/soldiers to explore nearby.`
   - NOT the old: "Scout the whole building site first."

**Pass if**: All error messages are actionable and explain next steps.

### Test 3: Zoom Clamping
1. Continue from Test 2
2. Scroll mouse wheel OUT (zoom out) continuously for 10+ scrolls
3. **CHECK**: Camera stops at readable strategic view; settlement buildings still clearly visible (not tiny specks)
4. Observe zoom level on minimap or by visual judgment
5. **EXPECTED**: Max zoom ~68 orthographic units (buildings ~1cm on screen at 1080p)
   - **NOT**: Max zoom 85 units (buildings become barely visible dots)

**Pass if**: Cannot accidentally zoom to "lost" view where settlement becomes invisible speck.

### Test 4: C&C Bar Functionality
1. Continue from Test 3
2. Find bottom build strip (C&C bar) - should show icon+name for each building type
3. Click **House** icon in bottom bar
4. **CHECK**: Enters placement mode with House ghost
5. Right-click to cancel
6. Click **Lumber Camp** icon in bottom bar
7. **CHECK**: Enters placement mode with Lumber Camp ghost
8. Right-click to cancel
9. Click **Watchtower** icon in bottom bar
10. **CHECK**: Enters placement mode with Watchtower ghost (Military category)
11. Right-click to cancel
12. Click **Barracks** icon in bottom bar
13. **CHECK**: Enters placement mode with Barracks ghost (Military category)

**Pass if**: All building types from C&C bar enter placement mode correctly, including Military buildings.

### Test 5: Barracks Large Footprint Validation
1. Continue from Test 4
2. Extend road from Town Hall entrance 6 tiles forward
3. Place **House** beside road (should succeed)
4. Try to place **Barracks** (5×3 footprint) overlapping the House
5. **CHECK**: Red footprint with message: `INVALID · Footprint overlaps another building. Move the ghost to an empty area.`
6. Try to place Barracks overlapping road
7. **CHECK**: Red footprint with message: `INVALID · Footprint blocked by road or rival structure. Try rotating (R) or move away from rival territory.`
8. Press **R** to rotate Barracks
9. **CHECK**: Footprint rotates, message updates if valid site found

**Pass if**: Large footprint validation messages suggest rotation and are clear about blocking cause.

---

## Track B Verification: Art Gap

### Test 6: Town Hall Distinctive Appearance
1. Start New Realm (seed 260821)
2. Observe founding scene (Day 1, tick 0)
3. **CHECK**: Town Hall has tall tower rising from main building
   - Tower should be ~3.9m tall (visual: tower height > 2× house height)
   - Building footprint visibly larger than nearby House would be (4.2×3.0 vs 3.2×2.8)
4. Zoom to NORMAL_ZOOM (scroll wheel to default view)
5. **CHECK**: Town Hall reads as civic/municipal building, NOT as "just another cottage"
   - Should have dual windows in tower (one low, one high)
   - Should have slate pyramid roof on tower
   - Should have flag/banner on tower peak
6. Compare to House (place one via BUILD → House beside road)
7. **CHECK**: House is clearly smaller, reads as residential cottage
8. **DISTINCTION MUST BE OBVIOUS** at founding: Town Hall = civic anchor, House = dwelling

**Pass if**: Town Hall is unmistakably a civic/government building distinct from cottage Houses.

### Test 7: Founding Yard Props Density
1. Continue from Test 6 (Day 1, founding scene)
2. Pan camera to Town Hall entrance (road tile in front of building)
3. Observe area within 3 tiles of entrance
4. **COUNT**: Visible decorative props (wood stacks, stone piles, barrels, crates)
   - **EXPECTED**: 8–12 props visible (12 attempted, some may be filtered by terrain)
   - **MINIMUM**: At least 8 props should be visible
5. **CHECK**: Yard feels "inhabited" with stacked supplies, not sparse/empty
6. Props should be:
   - Wood stacks (brown logs)
   - Stone stacks (gray rocks)
   - Barrels (brown cylinders)
   - Crates (brown boxes)
7. All props should be near entrance, not scattered randomly

**Pass if**: Founding yard has 8+ visible props creating inhabited settlement feel (vs sparse empty grass in .18).

### Test 8: Castle Morph Preservation
1. Continue from Test 7
2. Play to establish economy: extend road, build House, Lumber Camp, Farm
3. Gather resources: Wood 35, Stone 20, Planks 12 (for Barracks cost)
4. Build **Barracks** beside road
5. Wait for Barracks construction to complete (workers deliver materials, build finishes)
6. **CHECK**: Town Hall visually transforms to Castle
   - Should gain turrets/towers
   - Should gain crenellations (battlements)
   - Should gain fortress appearance matching title splash art
7. Pan camera around Castle
8. **CHECK**: No frame freeze, no lag spike, smooth rotation
   - **CRITICAL**: Castle view is cached (freeze-guard working)
   - NOT: Per-frame rebuild causing freeze (bug from playtest.10)
9. Select Castle, check inspector
10. **CHECK**: Building type still shows as "Town Hall" (or "Castle" if display name updated)

**Pass if**: Castle morph works smoothly without freeze; matches title fortress craft language at strategic zoom.

---

## Automated Test Verification

Run full test suite after model regeneration:

```powershell
.\tools\verify_release.ps1
```

**Critical suites for playtest.19**:
- `phase3_1_ux_rescue_smoke.gd` — C&C bar functionality, Barracks placement
- `phase3_ui_interaction_smoke.gd` — Placement click, ghost validation
- `phase3_real_game_playthrough.gd` — Full economy loop, Barracks construction
- `phase2_production_3d_smoke.gd` — Placement ghost rendering, Town Hall founding

**Expected**: 20/20 suites PASS  
**If failures**: Check model regeneration completed successfully; verify no regressions in placement validation logic.

---

## Manual Wine Playtest (10 minutes)

Replicate Grok Bot's playtest.18 Wine session:

1. **Start**: New Realm, seed 260821
2. **Minute 0-2**: Found Town Hall, observe founding yard props, verify Town Hall distinctive
3. **Minute 2-4**: Extend road, build House beside road (test placement UX, color legend)
4. **Minute 4-6**: Build Lumber Camp, verify workers start harvesting
5. **Minute 6-8**: Build Farm, extend roads toward trees
6. **Minute 8-10**: Attempt Watchtower placement (test C&C bar icon), verify Military category works
7. **Minute 10**: Attempt Barracks placement over invalid site, verify error message actionable

**RECORD**:
- Screenshots at minutes 2, 5, 8, 10
- First confusing moment (if any)
- First "this is better than .18" moment
- Any placement interaction confusion
- Any zoom "lost" view incidents
- Town Hall reads as civic building? (yes/no)
- Founding yard feels inhabited? (yes/no)

---

## Known Issues / Expected Behavior

### Not Bugs:
- **Founding props count varies**: 8–12 props spawn depending on terrain. Map RNG may block some placements. 8+ visible is expected.
- **Town Hall size**: 4.2×3.0 footprint is larger than House 3.2×2.8 but NOT as large as Barracks 5×3. This is correct.
- **Zoom max**: 68 units is strategic view, NOT close-up. Buildings should be ~1cm on screen at 1080p. This is the NEW correct max.
- **Castle morph timing**: Happens when Barracks completes construction, not when placed. This is correct behavior.

### Regressions to Watch:
- ❌ Castle freeze on Barracks completion → freeze-guard broken, reopen issue
- ❌ Placement ghost invisible → rendering pipeline broken
- ❌ C&C bar icons don't enter placement → connection to begin_placement broken
- ❌ Validation messages reverted to old text → merge conflict or wrong branch

---

## Sign-Off Criteria

**Ready for closed Steam playtest if**:
- ✅ All 8 verification tests pass
- ✅ 20/20 automated suites pass
- ✅ Wine 10-minute playtest shows improvements over .18
- ✅ No P0 regressions (castle freeze, placement broken, zoom broken)
- ✅ Town Hall reads as civic building in founding screenshots
- ✅ Founding yard feels inhabited (8+ props visible)

**NOT ready if**:
- ❌ Town Hall still looks like a cottage (art change failed)
- ❌ Placement errors still opaque (validation messages not updated)
- ❌ Zoom can reach "tiny speck" view (clamp failed)
- ❌ C&C bar icons don't work for Military buildings (wiring broken)
- ❌ Castle morph freezes game (freeze-guard regression)

---

## Troubleshooting

**Opening style models not updated?**
```bash
# Check if town_hall.tscn was modified
git status
# Should show: modified: assets/settlement3d/runtime/opening_style/town_hall.tscn

# If not modified, regeneration failed. Check:
ls -la assets/settlement3d/runtime/opening_style/
# Should show town_hall.tscn with recent timestamp

# Re-run generator with verbose output:
godot --headless --script tools/build_opening_style_models.gd
```

**Validation messages not updated?**
- Check: `src/GodotClient/Scripts/one_shard_simulation.gd` lines 787-847
- Should contain new messages like "Unrevealed terrain. Build closer to existing structures..."
- If old messages present: wrong branch or merge conflict

**C&C bar icons not working?**
- Check: `src/GodotClient3D/Scripts/production_3d_game_root.gd` line 978
- Should read: `btn.pressed.connect(begin_placement.bind(building_type))`
- If missing: connection broken, revert or fix wiring

**Castle freeze happening?**
- Check: Catalog building path logic for CASTLE view caching
- Should NOT rebuild mesh on every frame when has_barracks = true
- If freezing: freeze-guard broken, revert playtest.19 or investigate Catalog changes

---

## Post-Merge Actions

After PR #17 merged to `codex/closed-playtest-candidate`:

1. ✅ Regenerate models on main dev machine
2. ✅ Commit regenerated models separately (if not in PR)
3. ✅ Build playtest.19 package
4. ✅ Run this verification guide
5. ✅ Update RELEASE_EXECUTION_STATUS.md with verification results
6. ✅ Tag commit: `git tag v0.2.0-playtest.19`
7. ✅ Wine playtest with Grok Bot (screenshot comparison vs .18)
8. ✅ If all green: proceed to Steam playtest candidate gate
9. ❌ If regressions: open issue, fix, iterate

---

**Playtest.19 Verification Guide**  
Created: 2026-09-27  
For: PR #17 into codex/closed-playtest-candidate  
Owner: BrotherHelmer  
Lead: Grok Bot (Wine playtest validation)
