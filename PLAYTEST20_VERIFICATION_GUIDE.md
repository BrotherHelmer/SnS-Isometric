# Playtest.20 Wine Verification Guide

Build: 0.2.0-playtest.20  
Date: 2026-09-27  
Focus: Placement legend visibility fix + founding yard density

## Wine-Checkable Gates

### 1. Placement Legend + Status Both Visible
**Gate:** Color legend and live status must be readable simultaneously during placement.

**Steps:**
1. Launch production_3d.tscn or Windows build
2. Click BUILD button
3. Select any building (House, Lumber Camp, Farm)
4. Observe placement panel at bottom center

**Expected:**
- Top line shows static legend: "GREEN = valid · YELLOW = needs clearing · RED = blocked"
- Bottom line shows dynamic status: "VALID · Can place here" or "INVALID · [reason]"
- Moving mouse over different tiles updates bottom line only
- Top line legend remains visible throughout placement
- Both lines readable without overlapping

**Pass if:** Both legend and status visible at same time during mouse movement over footprints.

### 2. Goals Panel Still Advances
**Gate:** Objectives panel must show correct progression after legend UI changes.

**Steps:**
1. Start New Realm via production_3d.tscn
2. Note first incomplete objective (should be "Give settler first order" or similar)
3. Give first manual order
4. Check Goals panel updates

**Expected:**
- Panel shows first incomplete objective
- Completing actions advances objectives
- UI refactor did not break objective display

**Pass if:** Goals text updates correctly after first player action.

### 3. Town Hall Civic Distinctiveness (from .19)
**Gate:** Town Hall must read as civic structure vs House/cottage at founding camera.

**Steps:**
1. Start New Realm
2. Observe Town Hall at default founding camera angle

**Expected:**
- Taller tower (3.9m) visible at strategic zoom
- Wider footprint (4.2×3.0) reads as civic vs cottage
- Dual windows, entrance porch clear

**Pass if:** Town Hall silhouette distinct from Houses without zooming close.

### 4. Founding Yard Props on 3D Path
**Gate:** Props must spawn when starting via production_3d.tscn (Windows build path).

**Steps:**
1. Start New Realm via production_3d.tscn
2. Observe area around Town Hall entrance

**Expected:**
- 15 decorative props visible (wood_stack, stone_stack, barrel, crate, long_crate)
- Props scattered around entrance road tiles
- Denser clustering than playtest.19 (was 12 props)
- Props do not appear on road tiles or Town Hall footprint

**Pass if:** Multiple stacks/crates visible near entrance without developer console commands.

### 5. Zoom Clamp Still OK (from .19)
**Gate:** Camera zoom range must prevent "lost" speck view.

**Steps:**
1. Zoom out fully with mouse wheel
2. Verify max zoom distance feels reasonable

**Expected:**
- Max strategic zoom ~68 units (not 85+)
- Scroll step smooth (~3.5 per wheel notch)
- Cannot zoom so far that settlement becomes invisible speck

**Pass if:** Max zoom shows province overview without losing settlement readability.

### 6. Castle Freeze Still OK After Barracks (from .11+)
**Gate:** Castle upgrade must not cause per-frame rebuild freeze.

**Steps:**
1. Build Town Hall (if not already founded)
2. Build Barracks within road network
3. Observe Town Hall visual upgrade to Castle
4. Watch performance for 10+ seconds

**Expected:**
- Town Hall morphs to Castle (4-tower fortress) once Barracks exists
- No frame drops or freeze during/after transition
- Freeze-guard: cached CASTLE view, not rebuilt every frame

**Pass if:** No observable freeze when Castle appears.

## Deferred / Not Wine-Checkable

- **Placement flow "feels like one clear action"**: Requires human pilot feedback, not automated check
- **Town Hall vs title art judgment**: Requires owner visual approval against `assets/art_direction/opening_style_v1`
- **Full match win/loss**: Requires extended play session
- **Lower-end GPU performance**: Requires different hardware
- **Clean Windows machine**: Requires physical non-dev PC

## Quick Pass Checklist

- [ ] Legend + status both visible during placement hover
- [ ] Goals panel advances after first order
- [ ] Town Hall civic silhouette distinct
- [ ] 15 founding props visible near entrance
- [ ] Zoom clamp prevents speck view
- [ ] No freeze after Castle upgrade

## Known Limitations

- Placement legend is now two lines; panel height adjusted +20px to fit
- Legend styled slightly smaller/muted (#a8b89c, 11pt) vs status (#e2d4ad, default)
- If panel overlaps with other UI, report as separate issue
- This is internal validation; external human pilots still required per ROADMAP P0 gates
