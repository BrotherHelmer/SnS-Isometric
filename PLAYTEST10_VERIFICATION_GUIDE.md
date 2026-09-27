# Playtest.10 Verification Guide

**Version:** 0.2.0-playtest.10  
**Branch:** `cursor/playtest10-fixes-0b92`  
**PR:** [#6](https://github.com/BrotherHelmer/SnS-Isometric/pull/6)  
**Base:** `codex/closed-playtest-candidate` (after PR #5, commit 5e97a6e)

---

## Critical Test Cases

### 🔴 P0 #1: Castle Upgrade No Longer Freezes

**Reproduction Path:**
1. Start new game (any seed)
2. Build Barracks and connect it to road network
3. Assign 2 Bread to central inventory
4. Wait for Barracks construction to complete (~30-45 seconds)
5. Wait for first soldier training cycle (~18 seconds)

**Expected Behavior:**
- ✅ Town Hall visibly transforms into Castle (adds turrets, royal banner)
- ✅ Game continues running smoothly (no frame freeze or hang)
- ✅ Can zoom, pan, select buildings normally for 60+ seconds after upgrade
- ✅ FPS remains stable (30-60 FPS depending on system)

**Failure Indicator:**
- ❌ Game freezes/hangs when Barracks completes
- ❌ Frame rate drops to <5 FPS after castle appears
- ❌ Cannot interact with UI after castle upgrade

**Root Cause (Fixed):**
`production_building_view_3d.gd` was detecting `has_barracks` state change every frame, causing infinite `configure()` → `apply_snapshot()` rebuild loop. Now `last_snapshot["has_barracks"]` is updated during castle upgrade to prevent re-detection.

---

### 🟡 P0 #2: Build Bar Selection Works Immediately

**Reproduction Path:**
1. Start game
2. Click on any building in the world (e.g. Town Hall) → inspector panel appears
3. Click **Road** button on bottom build bar
4. Click elsewhere on map → placement completes
5. Click **House** button immediately (without deselecting anything)
6. Repeat for **Farm**, **Barracks**, **Watchtower**, **Clear Area**

**Expected Behavior:**
- ✅ Every build-bar button click immediately starts that placement mode
- ✅ No need to click Escape or deselect buildings first
- ✅ Switching between placement types works cleanly
- ✅ All 14 building types visible on bottom bar:
  - Road, House, Lumber Camp, Quarry, Farm, Sawmill, Bakery, Storehouse
  - Wall, Watchtower, Barracks, Lumen Pillar, Outpost, Clear Area
- ✅ Tooltips show building name, purpose, and costs

**Failure Indicator:**
- ❌ Clicking build button does nothing when building is selected
- ❌ Must press Escape before build button works
- ❌ Clear Area missing from bottom bar (only in category menu)

**Root Cause (Fixed):**
- `TOOL_CLEAR_AREA` was missing from `BUILD_PALETTE` constant
- `begin_placement()` now explicitly cancels drag/map state before starting new mode

---

### 🟡 P0 #3: Audio is Audible and Farm Sheep Present

**Reproduction Path:**
1. Start new game
2. Listen for BGM (should start within 2-3 seconds)
3. Build Lumber Camp, assign worker → listen for chop sounds
4. Build Farm, wait for completion → listen for sheep bleat on completion
5. Build Sawmill, assign worker → listen for saw sounds
6. Build Barracks, wait for completion → listen for military ready sound

**Expected Behavior:**
- ✅ **BGM**: Looping pastoral theme audible from game start (not silent)
- ✅ **Farm complete**: Clear sheep bleat when Farm construction finishes
- ✅ **Work SFX**: Chop/saw sounds while Lumber Camp/Sawmill staffed (rate-limited)
- ✅ **Barracks**: Military acknowledgment sound when Barracks ready
- ✅ **Spawn sounds**: Subtle arrival sounds when settlers arrive (not always obvious but present)
- ✅ **No clipping**: Audio doesn't distort even with multiple SFX playing

**Volume Levels (Post-Fix):**
- Master: 1.0 (unchanged)
- Music: 0.85 (was 0.72, +18%)
- SFX: 1.0 (was 0.85, +17%)
- Day stem: -8dB (was -11dB, +3dB boost)
- Ambience: -11dB (was -13dB, +2dB boost)

**BGM Integration (Playtest.10):**
- Primary settlement BGM: `bgm_settlement_loop.ogg` (94.5s pastoral town theme, cynicmusic CC0)
- Replaces: `score_pastoral_foundation.wav` (now using full-length original CC0 theme)
- Ambient bed: `ambient_world.wav` (26s nature bed, Spring Spring CC0)
- Replaces: `settlement_wind_birds.wav` (now using dedicated nature-only ambient)

**Failure Indicator:**
- ❌ BGM is silent or barely audible even at full volume
- ❌ Farm completion plays no sound
- ❌ Work sounds never play even with staffed buildings
- ❌ Audio clips/distorts during gameplay

**Files Verified Present:**
- `assets/settlement/audio/farm_animal.wav` (farm completion - updated louder/clearer)
- `assets/settlement/audio/settler_arrive_worker.wav` (civilian spawn)
- `assets/settlement/audio/settler_arrive_soldier.wav` (military spawn)
- `assets/settlement/audio/barracks_ready.wav` (barracks ready)
- `assets/settlement/audio/presentation/bgm_settlement_loop.ogg` (BGM day - NEW playtest.10)
- `assets/settlement/audio/presentation/ambient_world.wav` (ambient - NEW playtest.10)
- All files are CC0 from PR #5 and playtest.10 curated pack (documented in AUDIO_LICENSE_LEDGER.md)

---

### 🟡 P0 #4: Camera Shows "Ant Farm" Settlement View

**Reproduction Path:**
1. Start new game
2. Observe default camera view (should be much wider than playtest.9)
3. Scroll mouse wheel DOWN to zoom out fully
4. Compare to attached Settlers II reference image

**Expected Behavior:**
- ✅ **Default view**: Much wider than playtest.9 (~73% larger)
- ✅ Can see multiple buildings, road network, and many settlers at once
- ✅ **Zoom out**: Can reach strategic "ant farm" overview
- ✅ Settlement reads as living colony of tiny agents (not close tactical view)
- ✅ Isometric perspective maintained (not top-down)
- ✅ Building placement raycasts still work at all zoom levels

**Zoom Constants (Post-Fix):**
- `CLOSE_ZOOM`: 18.0 (unchanged)
- `NORMAL_ZOOM`: **38.0** (was 22.0, **+73% wider**)
- `STRATEGIC_ZOOM`: **85.0** (was 58.0, **+46% wider**)

**Failure Indicator:**
- ❌ Default view feels like playtest.9 (close-up, few buildings visible)
- ❌ Cannot zoom out far enough to see full settlement layout
- ❌ Still feels like tactical RTS instead of "watching ants work"

---

## Regression Checks

These should still work after the fixes:

- ✅ Saving and loading games
- ✅ Building placement (rotation with R, drag roads/walls)
- ✅ Worker assignment and pathfinding
- ✅ Day/night cycle and enemy raids
- ✅ Resource production chains (wood → planks → bread)
- ✅ Selection ring on buildings/workers
- ✅ Inspector panel shows building info
- ✅ Pause, speed controls, menu
- ✅ Game can reach victory/defeat conditions

---

## Quick Smoke Test (5 minutes)

1. Start new game (seed: 260821 for consistency)
2. Build Lumber Camp → Farm → Sawmill → Barracks
3. Listen for BGM, farm sheep, work sounds
4. Wait for Barracks completion → verify castle upgrade, no freeze
5. Click multiple build buttons rapidly → verify all work without deselect
6. Zoom out fully → verify wide "ant farm" view
7. Play for 2-3 minutes → verify smooth framerate, no hangs

**Pass:** All audio present, no freeze, build bar responsive, camera wide  
**Fail:** Any freeze, silent audio, build buttons broken, camera still close

---

## Known Limitations (Out of Scope)

These were NOT addressed in this PR:

- PvP caravan/MMO features (future scope, not isometric demo scope)
- Additional BGM variants (current CC0 stems sufficient)
- Procedural synth SFX (hard constraint: only real CC0in runtime)
- UI/HUD styling overhaul (separate polish task)

---

## Build & Test Commands

### Windows (PowerShell):
```powershell
# Build release package
.\tools\build_release.ps1

# Output: dist/ShardAndSovereign_0.2.0-playtest.10/
```

### Run from source (Godot 4.7):
```bash
# With Godot 4.7 in PATH:
godot --path . res://src/GodotClient3D/Scenes/production_3d.tscn
```

---

## Success Criteria

All 4 P0 bugs must be verifiably fixed:

1. ✅ Castle upgrade → no freeze, playable for 60+ seconds after
2. ✅ Build bar buttons work immediately, no deselect needed, 14 types visible
3. ✅ Audio audible (BGM + SFX), farm sheep present, no clipping
4. ✅ Default camera ~73% wider, strategic zoom shows full settlement

**If all pass:** Playtest.10 is ready for daily demo build.  
**If any fail:** See root cause sections above, verify fix was applied correctly.

---

**Last Updated:** September 27, 2026  
**Author:** Cursor Cloud Agent (playtest.10 bug fixes)
