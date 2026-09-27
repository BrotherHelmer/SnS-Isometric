# Playtest.9 Audio Status - Real CC0 Required

**Date**: September 27, 2026  
**PR**: [#5](https://github.com/BrotherHelmer/SnS-Isometric/pull/5)  
**Branch**: `cursor/playtest9-fixes-ba37`  
**Version**: 0.2.0-playtest.9

---

## Helmer's Requirements (ALL ADDRESSED IN CODE)

### ✅ 1. Deleted Procedural Placeholders
- **DELETED**: `assets/settlement/audio/farm_animal.wav` (procedural sheep bleat)
- **DELETED**: `assets/settlement/audio/settler_arrive.wav` (procedural chime)
- **DELETED**: Associated `.import` files
- **Status**: Procedural synthesis removed from runtime audio

### ✅ 2. Soft-Deprecated Generation Script
- **File**: `tools/generate_playtest9_placeholder_audio.py`
- **Status**: Header updated with deprecation notice
- **Message**: "SOFT-DEPRECATED: Do not use for runtime audio"
- **Note**: Script retained for reference only, not for shipping runtime sounds

### ✅ 3. Per-Type Settler Spawn Sounds (WIRED)
Code now emits **distinct** audio events based on settler type:

#### Civilian/Worker Spawns
- **Event**: `settler_spawn_worker`
- **File**: `settler_arrive_worker.wav` (TO BE ADDED)
- **Types**: carrier, woodcutter, miner, farmer, sawyer, baker, clearer
- **Wired**: Population growth (founding + food-cost arrivals) in `_update_population_growth()`

#### Military/Guard Spawns
- **Event**: `settler_spawn_guard`
- **File**: `settler_arrive_guard.wav` (TO BE ADDED)
- **Types**: guard (soldier), ranger (tower guard)
- **Wired**: Barracks soldier training completion in `_tick_barracks_training()`

### ✅ 4. Barracks Completion Sound
- **Event**: `barracks_complete`
- **File**: `barracks_ready.wav` (TO BE ADDED — or fallback to `soldier.wav`)
- **Character**: Prefer real CC0 voice grunt/acknowledgment "huh/ready"
- **Current**: Falls back to `soldier.wav` (Kenney metal jingle) if `barracks_ready.wav` missing
- **Wired**: Building completion path checks building type

### ✅ 5. Farm Completion Sound
- **Event**: `farm_complete`
- **File**: `farm_animal_complete.wav` (TO BE ADDED)
- **Character**: Real sheep/farm animal bleat
- **Wired**: Building completion path checks building type

### ✅ 6. Comprehensive Documentation
- **`docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md`**: Full CC0 sourcing guide (updated)
- **`assets/settlement/audio/TODO_REQUIRED_CC0_AUDIO.md`**: Exact file specifications (new)
- **`docs/art/AUDIO_LICENSE_LEDGER.md`**: Procedural rejection note, CC0 requirements

---

## Code Changes Summary

### Audio Director (`production_audio_director.gd`)
```gdscript
const CUE_PATHS := {
    // ...existing...
    "farm_complete": "res://assets/settlement/audio/farm_animal_complete.wav",
    "barracks_complete": "res://assets/settlement/audio/barracks_ready.wav",
    "settler_spawn_worker": "res://assets/settlement/audio/settler_arrive_worker.wav",
    "settler_spawn_guard": "res://assets/settlement/audio/settler_arrive_guard.wav"
}

func handle_sim_event(event_name: String) -> void:
    match event_name:
        "farm_complete": play_cue("farm_complete")
        "barracks_complete": play_cue("barracks_complete")
        "settler_spawn_worker": play_cue("settler_spawn_worker")
        "settler_spawn_guard": play_cue("settler_spawn_guard")
```

### Simulation (`one_shard_simulation.gd`)
```gdscript
// Population growth (civilian spawns)
func _update_population_growth(delta: float) -> void:
    // ...
    _emit_audio("settler_spawn_worker")  // Was: "settler_spawn"

// Soldier training (military spawns)
func _tick_barracks_training(delta: float) -> void:
    // ...
    _emit_audio("settler_spawn_guard")   // Was: "soldier"

// Building completion
func _complete_construction(...):
    if building_type == Defs.BUILDING_FARM:
        _emit_audio("farm_complete")
    elif building_type == Defs.BUILDING_BARRACKS:
        _emit_audio("barracks_complete")
    else:
        _emit_audio("build_complete")
```

---

## Missing Files (BLOCKING MERGE)

These real CC0 recordings must be added before PR #5 can merge:

| File | Purpose | Required? | Fallback |
|------|---------|-----------|----------|
| `farm_animal_complete.wav` | Farm completion | **YES** | None — will error if missing |
| `settler_arrive_worker.wav` | Civilian spawn | **YES** | None — will error if missing |
| `settler_arrive_guard.wav` | Military spawn | **YES** | None — will error if missing |
| `barracks_ready.wav` | Barracks completion | Optional | Falls back to `soldier.wav` (Kenney jingle) |

---

## File Specifications

All files must meet:
- **Format**: WAV
- **Bit Depth**: 16-bit
- **Channels**: Mono
- **Sample Rate**: 44.1kHz
- **Peak Level**: Normalized to ≈-1dB
- **Fades**: 5-15ms fade-in/out to eliminate clicks
- **License**: CC0 (Public Domain) from approved sources

---

## Approved CC0 Sources

Helmer has already accepted these packs for playtest.8:
- **Kenney** (kenney.nl): Impact Sounds, RPG Audio, Music Jingles, Interface Sounds
- **rubberduck** (OpenGameArt): 100 CC0 metal and wood SFX
- **qubodup** (OpenGameArt): Footsteps, bamboo stick whooshes
- **Vehicle / tinysized** (OpenGameArt): Fantasy Sound Effects (handsaw, arrow, whoosh)
- **OwlishMedia** (OpenGameArt): 87 Clickety Clips
- **HaelDB** (OpenGameArt): RPG Sound Pack (NPC/monster grunts)
- **LFA** (OpenGameArt): Monster Sound Pack Volume 2
- **Brandon Morris, Robin Lamb, Kresiek, congusbongus** (OpenGameArt): Various CC0 packs

**Prefer** downloading from these known-good sources.

---

## Recommended Files (If Sourcing Manually)

### Farm Animal Complete
- **Search**: Freesound "sheep bleat CC0" or OpenGameArt farm packs
- **Example**: Single sheep bleat, 0.8-1.5s duration
- **Processing**: Trim to bleat event, normalize, fade

### Settler Arrive Worker
- **Option 1**: Layer qubodup footsteps + rubberduck wood door creak
- **Option 2**: Kenney Interface Sounds arrival/greeting sound
- **Duration**: 0.6-1.2s
- **Processing**: Layer if needed, normalize, fade

### Settler Arrive Guard
- **Prefer**: HaelDB RPG Sound Pack CC0 voice grunt (short "huh" or acknowledgment)
- **Fallback**: rubberduck metal clink + Kenney RPG weapon sound
- **Duration**: 0.8-1.5s
- **Processing**: Select short grunt, normalize, fade
- **NO commercial game VO** (no AoE, Warcraft, Starcraft)

### Barracks Ready (Optional)
- **Prefer**: HaelDB or LFA CC0 voice grunt "ready" style
- **Fallback**: Keep using `soldier.wav` (Kenney metal jingle — already CC0)
- **Duration**: 0.8-1.5s

---

## Processing Workflow

```bash
# Convert to mono 16-bit 44.1kHz WAV
ffmpeg -i input.wav -ac 1 -ar 44100 -sample_fmt s16 output.wav

# Normalize to -1dB peak
ffmpeg -i output.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" normalized.wav

# Add fades (5ms in, 10ms out)
ffmpeg -i normalized.wav -af "afade=t=in:st=0:d=0.005,afade=t=out:st=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 normalized.wav | awk '{print $1-0.01}'):d=0.01" final.wav
```

---

## Next Steps

### For Manual Curation (If Helmer Provides CC0 ZIP)
1. Extract curated WAV files
2. Check they meet specifications (16-bit mono, 44.1kHz, normalized)
3. Place in `assets/settlement/audio/` with exact filenames above
4. Copy provenance from provided `PROVENANCE.md` to `AUDIO_LICENSE_LEDGER.md`
5. Test in-game

### For Self-Sourcing (If Cloud Agent Can Download)
1. Search Freesound/OpenGameArt for CC0 files matching character descriptions
2. Download high-quality WAV or OGG
3. Process to specification (see workflow above)
4. Place in correct paths
5. Document provenance (author, pack, URL, CC0 license)
6. Test in-game

### For Testing Without Real Audio (Temporary)
- Game will run but log errors for missing files
- Audio events will silently fail (no sound)
- **NOT acceptable for merge** — real files required

---

## What's Already Working

### ✅ Visual Fixes (From Original PR)
- Town Hall → Castle upgrade when Barracks built
- Bottom C&C build bar fully clickable
- Building icons + tooltips

### ✅ Existing Audio (Playtest.8, CC0)
- Background music stems (crossfade by game state)
- `work_chop.wav` (lumber camp) — CC0
- `saw.wav` (sawmill) — CC0
- `work_hammer.wav` (generic work) — CC0
- `soldier.wav` (currently used for barracks) — CC0

### ✅ Audio System (Wired & Ready)
- Per-type spawn events emit correctly
- Building-specific completion events
- Audio director handles all new event types
- Fallback to `soldier.wav` for barracks if `barracks_ready.wav` missing

---

## Summary

**Code Status**: ✅ All wiring complete, per-type spawn sounds implemented  
**Audio Status**: 🔴 Blocking — 3-4 real CC0 files required  
**Visual Fixes**: ✅ Intact from original PR  
**Documentation**: ✅ Comprehensive CC0 sourcing guides  
**Merge Blocker**: Real CC0 audio files must be added (see `TODO_REQUIRED_CC0_AUDIO.md`)

The game is **ready to receive** real CC0 audio. Once files are added:
- No code changes needed
- Audio will work immediately
- Just document provenance and test

---

Last Updated: September 27, 2026
