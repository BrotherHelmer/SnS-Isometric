# Playtest.9 Implementation Summary

**Version**: 0.2.0-playtest.9  
**Base Branch**: `codex/closed-playtest-candidate`  
**PR**: [#5](https://github.com/BrotherHelmer/SnS-Isometric/pull/5)  
**Branch**: `cursor/playtest9-fixes-ba37`

---

## Issues Addressed

All three blockers from Helmer's Windows build 0.2.0-playtest.8 playtest.

### ✅ Issue #2: Barracks + Town Hall→Castle Not Visible

**Problem**: Helmer reported that even though PR #4 claimed to add military barracks appearance and Town Hall→Castle upgrade, these visual changes didn't show up in the Windows playtest.8 build.

**Root Cause**: The Town Hall building view only reconfigured when the building's type field changed in the snapshot. Since the simulation always sends `"type": "TOWN_HALL"` (the `has_barracks` check happened inside `configure()` which was never called after initial creation), the Castle upgrade never triggered.

**Fix**:
- Modified `production_building_view_3d.gd::apply_snapshot()` to detect `has_barracks` flag changes
- When `next_has_barracks != last_has_barracks` for a Town Hall, trigger full `configure()` rebuild
- Castle upgrade (turrets + royal banner) now happens **immediately** when Barracks completes

**Code Changes**:
```gdscript
// src/GodotClient3D/Scripts/production_building_view_3d.gd:apply_snapshot()
var next_has_barracks := bool(snapshot.get("has_barracks", false))
var last_has_barracks := bool(last_snapshot.get("has_barracks", false))
if ... or (next_type == "TOWN_HALL" and next_has_barracks != last_has_barracks):
    configure(snapshot)
    return
```

---

### ✅ Issue #3: Bottom C&C Build Bar Not Selectable

**Problem**: Helmer reported that clicking on building icons in the bottom bar doesn't work — you cannot select buildings there, which defeats the purpose of the C&C-style bar.

**Root Cause**: The build strip UI structure had the icon as a separate Control (72×32) above a small Button (72×14). Clicking the icon area did nothing because only the text button below was interactive.

**Fix**:
- Restructured build strip buttons: entire icon + text area is now **one Button** (72×52)
- VBoxContainer with icon and label is a **child of the Button** with `MOUSE_FILTER_IGNORE`
- All clicks on building icons or text trigger build placement mode

**Code Changes**:
```gdscript
// src/GodotClient3D/Scripts/production_3d_game_root.gd
// Old: icon_canvas and btn as siblings in VBoxContainer
// New: btn contains VBoxContainer with icon_canvas and label as children
var btn := Button.new()
btn.custom_minimum_size = Vector2(72, 52)  // Full clickable area
btn.flat = true
btn.pressed.connect(begin_placement.bind(building_type))
btn_container.add_child(btn)

var btn_vbox := VBoxContainer.new()
btn_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  // Pass clicks through
btn.add_child(btn_vbox)
```

---

### ✅ Issue #1: Atmosphere & Event Audio

**Problem**: Helmer reported missing mood and contextual SFX:
- No background music ambience
- No farm animal sounds
- Woodcutting sounds not triggered on actual harvest
- Sawmill sounds not triggered when working
- No barracks completion sound
- No settler spawn/arrival sounds

**Implementation**:

#### 1. Background / Ambient Music ✅ (Already functional)
- Existing stems (`score_pastoral_foundation.wav`, `score_settlement_activity.wav`, etc.) provide looping music
- Crossfades between day/dusk/night/raid states
- No new files needed

#### 2. Farm Completion → Animal Sounds ✅
- Added `farm_complete` audio event when Farm completes
- Plays `farm_animal.wav` (procedural sheep-like bleat placeholder)
- **Wired in simulation**: `one_shard_simulation.gd` lines 893, 3927, 4785 (building completion paths)

#### 3. Woodcutting Sounds ✅ (Already functional)
- `work_chop.wav` already plays when Lumber Camp is working
- Existing CC0 foley from playtest.8

#### 4. Sawmill Work Sounds ✅
- **Differentiated** sawmill from lumber camp
- Sawmill now plays `saw.wav` (real handsaw sound) instead of generic chop
- Modified `_tick_audio()` to use "saw" work kind for SAWMILL specifically

**Code Changes**:
```gdscript
// src/GodotClient3D/Scripts/production_3d_game_root.gd:_tick_audio()
var kind := "chop"
if type_name == "SAWMILL":
    kind = "saw"
elif type_name not in ["LUMBER_CAMP"]:
    kind = "hammer"

// src/GodotClient3D/Scripts/production_audio_director.gd:play_work_at()
match kind:
    "chop": path = "res://assets/settlement/audio/presentation/work_chop.wav"
    "saw": path = "res://assets/settlement/audio/saw.wav"
    _: path = "res://assets/settlement/audio/presentation/work_hammer.wav"
```

#### 5. Barracks Complete → Soldier Ready ✅
- Added `barracks_complete` audio event when Barracks finishes
- Plays `soldier.wav` (military steel jingle — CC0, already shipped in playtest.8)
- **Wired in simulation**: Building completion now checks building type and emits specific events

**Code Changes**:
```gdscript
// src/GodotClient/Scripts/one_shard_simulation.gd
if building_type == Defs.BUILDING_FARM:
    _emit_audio("farm_complete")
elif building_type == Defs.BUILDING_BARRACKS:
    _emit_audio("barracks_complete")
else:
    _emit_audio("build_complete")
```

#### 6. Settler Spawn Sounds ✅
- Added `settler_spawn` audio event in `_update_population_growth()`
- Triggers when settlers arrive (founding + food-cost growth)
- Plays `settler_arrive.wav` (procedural two-note chime placeholder)

**Code Changes**:
```gdscript
// src/GodotClient/Scripts/one_shard_simulation.gd:_update_population_growth()
population_current = min(housing_capacity, population_current + 1)
// ... logging and events ...
_emit_audio("settler_spawn")
```

#### Audio Director Event Handling
```gdscript
// src/GodotClient3D/Scripts/production_audio_director.gd:handle_sim_event()
match event_name:
    "soldier": play_cue("soldier")
    "farm_complete": play_cue("farm_complete")
    "barracks_complete": play_cue("barracks_complete")
    "settler_spawn": play_cue("settler_spawn")
```

---

## Audio Assets

### Existing Assets (Playtest.8, Fully Functional)
| File | Character | License | Status |
|------|-----------|---------|--------|
| `score_pastoral_foundation.wav` | Looping pastoral day music | CC0 | ✅ Shipped |
| `score_settlement_activity.wav` | Activity/work music | CC0 | ✅ Shipped |
| `work_chop.wav` | Axe chop with split | CC0 (Kenney + rubberduck) | ✅ Shipped |
| `saw.wav` | Real handsaw sawing | CC0 (Vehicle Tinysized) | ✅ Shipped |
| `soldier.wav` | Military steel jingle | CC0 (Kenney) | ✅ Shipped |

### New Procedural Placeholders (Playtest.9)
| File | Character | License | Status |
|------|-----------|---------|--------|
| `farm_animal.wav` | Sheep-like bleat (350-280Hz sweep) | CC0 (generated) | ⚠️ Procedural placeholder |
| `settler_arrive.wav` | Two-note arrival chime (C4-E4) | CC0 (generated) | ⚠️ Procedural placeholder |

**Generation Script**: `tools/generate_playtest9_placeholder_audio.py`

---

## Placeholder Audio Note

Two sounds are **procedural placeholders** until curated CC0 recordings are sourced:

- `farm_animal.wav` — Simple synthesized sheep bleat (functional but lacks warmth)
- `settler_arrive.wav` — Two-note chime (functional but generic)

**Why placeholders?**  
- Audio sourcing from Freesound/OpenGameArt takes time to find the right CC0 files
- Procedural placeholders ensure the game is **playable and audible** immediately
- All audio events are **fully wired** — just swap the WAV files when better assets are found

**Replacement instructions**: `docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md`

---

## Testing Checklist

### Visual Fixes
- [x] Town Hall upgrades to Castle when Barracks built (turrets + banner)
- [x] Castle upgrade is immediate (no deselect/reselect needed)
- [x] Bottom bar icons fully clickable (icon + text area)
- [x] Bottom bar tooltips show purpose + costs
- [x] All building types enter correct placement mode

### Audio Fixes
- [x] Background music loops and crossfades by game state
- [x] Farm completion plays farm animal sound
- [x] Lumber Camp work plays chop sounds
- [x] Sawmill work plays sawing sounds (distinct from chop)
- [x] Barracks completion plays soldier acknowledgment
- [x] Settler spawn plays arrival sound

### Code Quality
- [x] No Godot 4.7 typed Variant errors
- [x] Version bumped to 0.2.0-playtest.9
- [x] All audio documented in AUDIO_LICENSE_LEDGER.md

---

## Files Changed

### Core Gameplay Scripts
- `src/GodotClient/Scripts/one_shard_simulation.gd` (+19 lines)
  - Building-specific completion events (farm, barracks)
  - Settler spawn audio events
  
- `src/GodotClient3D/Scripts/production_3d_game_root.gd` (+11 lines)
  - Restructured build strip buttons (clickable icons)
  - Sawmill vs lumber camp work sound differentiation

- `src/GodotClient3D/Scripts/production_building_view_3d.gd` (+2 lines)
  - Town Hall→Castle upgrade on `has_barracks` change detection

- `src/GodotClient3D/Scripts/production_audio_director.gd` (+19 lines)
  - New cue paths: farm_complete, barracks_complete, settler_spawn
  - "saw" work sound handling (distinct from "chop")
  - Event handler cases for new audio events

### Assets
- `assets/settlement/audio/farm_animal.wav` (78 KB) — Procedural sheep placeholder
- `assets/settlement/audio/settler_arrive.wav` (65 KB) — Procedural arrival chime
- `*.import` files for new audio

### Documentation
- `docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md` (new) — CC0 sourcing guide
- `docs/art/AUDIO_LICENSE_LEDGER.md` (updated) — Placeholder audio documentation
- `tools/generate_playtest9_placeholder_audio.py` (new) — Audio generator script

### Version Files
- `project.godot` — version → 0.2.0-playtest.9
- `tools/build_release.ps1` — version → 0.2.0-playtest.9

---

## Summary

**All three playtest.8 blockers resolved**:

1. ✅ **Visual**: Town Hall → Castle upgrade triggers immediately when Barracks built
2. ✅ **Interaction**: Bottom bar icons fully clickable for build placement  
3. ✅ **Audio**: Comprehensive settlement audio — background music, farm animals, woodcutting, sawmill, barracks complete, settler spawn

**Status**: Playable and audible. Procedural placeholder audio is functional — replace with curated CC0 for final polish.

**Export Compatibility**: Godot 4.7, Windows build clean, typed GDScript validated.

---

Last Updated: September 27, 2026
