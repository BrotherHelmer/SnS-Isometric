# Audio License Ledger

This document tracks all audio assets used in Shard & Sovereign and their licenses.

## Settlement SFX (CC0 Real Foley - Playtest.8 v3)

**Curated**: September 27, 2026  
**Source Archive**: `cc0-settlement-sfx-v3.zip`  
**License**: CC0 (Public Domain)  
**Provenance Document**: `docs/art/AUDIO_PROVENANCE_V3.md`  
**Character**: Real recorded foley and curated CC0 game SFX with Settlers-II work-soul — warm, physical colony-building audio

### Audio Approach

These are **curated real CC0 recordings and game audio**, NOT procedural synthesis:
- Layered real foley (wood impacts, metal hits, saws, hammers, footsteps)
- Curated from multiple CC0 packs: Kenney Impact/RPG/Jingles/Interface, rubberduck 100 CC0 metal+wood SFX, qubodup footsteps, Vehicle Tinysized SFX, OwlishMedia clicks, HaelDB growls, Brandon Morris completion, etc.
- Edited for timing, fades (5–15ms), mono channel, 44.1kHz 16-bit PCM
- Peak normalized to ≈ −1 dB for consistent volume and headroom
- Each sound combines 1–5 source files with careful layering/delays/filtering

### Files

| File | Duration | Character | Sources |
|------|----------|-----------|---------|
| `ui_click.wav` | 0.20s | Soft wooden tap with quiet click | rubberduck wood_hit_01 + OwlishMedia click26 |
| `build_start.wav` | 0.45s | Hammer into wood | rubberduck hammer_01 + wood_hit_03 |
| `build_complete.wav` | 0.69s | Warm success sting | Brandon Morris completetask + Robin Lamb Ding |
| `delivery.wav` | 0.42s | Crate drop with weight | rubberduck wood_slam + Kenney impactPlank_medium |
| `road.wav` | 0.45s | Gravel scrape + stone | qubodup gravel + stone01 footsteps |
| `woodchop.wav` | 0.31s | Axe chop with split | Kenney chop + rubberduck wood layers + impactWood_heavy |
| `saw.wav` | 0.55s | Real handsaw sawing | Vehicle handsaw-sawing-wood-01 (rhythmic section) |
| `attack.wav` | 0.38s | Combat weapon hit | rubberduck metal_hit + Kenney impactMetal_heavy + Vehicle hammer |
| `tower.wav` | 0.44s | Arrow launch whoosh | qubodup bamboo swosh + Vehicle arrow-feathers + whoosh |
| `enemy.wav` | 0.70s | Ominous growl/sting | HaelDB gutteral beast + LFA Monster-1 + congusbongus abyss (lowpass) |
| `night.wav` | 1.05s | Descending tense chord | Kresiek dark_stinger + congusbongus abyss |
| `soldier.wav` | 0.85s | Military steel jingle | Kenney jingles_STEEL05 + confirmation_001 |
| `destroyed.wav` | 1.16s | Building collapse | rubberduck: wood_breaking, crack, slam, dual falling (staggered) |

### Technical Specifications

- **Format**: WAV, 16-bit mono, 44.1kHz
- **Peak Level**: Normalized to ≈ −1 dB
- **Processing**: 
  - Short fades (5–15 ms) to eliminate clicks
  - Layering with carefully timed delays (10–40 ms)
  - Filtering (lowpass beds, noise reduction where needed)
  - Mono channel mix
  - Trimmed to action-appropriate durations (0.20–1.16 s)

### What Makes These Real Foley Not Synthesis

**Previous v2** (rejected by Helmer): Procedural organic synthesis with advanced techniques but no recorded soul

**Current v3**:
1. **Real recordings**: Actual wood impacts, metal hits, saws, footsteps, growls, bells
2. **Curated from trusted CC0 packs**: Kenney (professional game audio), rubberduck (OGA foley master), qubodup, Vehicle Tinysized, etc.
3. **Physical character**: Real acoustic properties, not algorithmic approximations
4. **Work-soul**: Settlers-II feel comes from real foley layering, not synthesis parameters
5. **Proven game audio**: Many sources are from shipped CC0 games and professional packs

### Source Packs Used

All CC0 (Creative Commons Zero / Public Domain):

- **Kenney** (www.kenney.nl): Impact Sounds, RPG Audio, Music Jingles, Interface Sounds — professional game audio packs
- **rubberduck** (OpenGameArt): 100 CC0 metal and wood SFX — extensive foley collection
- **qubodup** (OpenGameArt): Different steps on wood/stone/leaves/gravel/mud, Swish bamboo stick whooshes
- **Vehicle (Jan Schupke / tinysized)** (OpenGameArt): Fantasy Sound Effects — real handsaw, arrow, whoosh recordings
- **OwlishMedia** (OpenGameArt): 87 Clickety Clips
- **HaelDB** (OpenGameArt): RPG Sound Pack — NPC/monster vocals
- **LFA** (OpenGameArt): Monster Sound Pack Volume 2
- **Brandon Morris** (OpenGameArt): Completion sound
- **Robin Lamb** (OpenGameArt): UI Sound Effects (from VCSL/VSCO 2 CE public-domain libraries)
- **Kresiek The Furry** (OpenGameArt): Dark Stinger 1
- **congusbongus** (OpenGameArt): String and piano horror stings

Full per-file attribution and source URLs: `docs/art/AUDIO_PROVENANCE_V3.md`

### Reproduction

Source archive: `cc0-settlement-sfx-v3.zip` (13 WAV files + PROVENANCE.md)

Installed paths:
```
assets/settlement/audio/ui_click.wav
assets/settlement/audio/build_start.wav
assets/settlement/audio/build_complete.wav
assets/settlement/audio/delivery.wav
assets/settlement/audio/road.wav
assets/settlement/audio/woodchop.wav
assets/settlement/audio/saw.wav
assets/settlement/audio/attack.wav
assets/settlement/audio/tower.wav
assets/settlement/audio/enemy.wav
assets/settlement/audio/night.wav
assets/settlement/audio/soldier.wav
assets/settlement/audio/destroyed.wav
```

---

## Music & Ambience (Existing Assets)

The following audio files in `assets/settlement/audio/presentation/` were present before playtest.8 and are documented separately:

- `score_pastoral_foundation.wav`
- `score_settlement_activity.wav`
- `score_dusk_tension.wav`
- `score_night_percussion.wav`
- `score_metal_combat.wav`
- `settlement_wind_birds.wav`
- `wyrd_drone.wav`
- `lumen_hum.wav`
- `nightfall_sting.wav`
- `dawn_release.wav`
- `victory_motif.wav`
- `defeat_motif.wav`
- `reckoning_pulse.wav`
- `night_scream.wav`

*(Legacy license status documented in AUDIO_ASSET_LEDGER.md)*

---

## Provenance Statement

All settlement SFX are **100% curated real CC0 recordings**:
- ✅ **Real foley** from trusted CC0 packs (Kenney, rubberduck, qubodup, Vehicle, etc.)
- ✅ **No Settlers II samples** or recreations of copyrighted melodies
- ✅ **No commercial game audio** used without proper CC0 licensing
- ✅ **Character inspired by genre feel** (Settlers-II-style colony sim work-soul)
- ✅ **All sources are CC0** with full attribution in AUDIO_PROVENANCE_V3.md

### Synthesis Scripts (Deprecated for Runtime Audio)

Previous versions explored procedural synthesis:
- `tools/generate_organic_settlement_audio.py` — advanced organic synthesis (v2, rejected)
- Earlier thin sine/FM generators (v1, rejected)

These scripts remain in the repository for reference but are **soft-deprecated** and NOT the shipped runtime audio. The 13 settlement SFX slots are now filled with curated real CC0 foley (v3).

---

## Attribution

### For CC0 Assets:
No attribution required by license. Optional credit:

> Settlement SFX: Curated CC0 foley from Kenney, rubberduck, qubodup, Vehicle/tinysized, OwlishMedia, HaelDB, LFA, Brandon Morris, Robin Lamb, Kresiek The Furry, congusbongus — full provenance in docs/art/AUDIO_PROVENANCE_V3.md

---

## Playtest.9 Required Audio (BLOCKING MERGE)

**Status**: September 27, 2026  
**Helmer Requirement**: Real CC0 foley ONLY — no procedural/synthesized placeholders  
**Blocking**: PR #5 cannot merge until these real CC0 recordings are added

### Missing Files (REQUIRED for Merge)

| File | Purpose | Character | Sources |
|------|---------|-----------|---------|
| `farm_animal_complete.wav` | Farm completion | Real sheep/farm animal bleat (0.8-1.5s) | Freesound CC0, OpenGameArt |
| `settler_arrive_worker.wav` | Civilian spawn | Footsteps + door or greeting (0.6-1.2s) | qubodup + rubberduck, Kenney |
| `settler_arrive_guard.wav` | Military spawn | **CC0 voice grunt** or armor clink (0.8-1.5s) | HaelDB, LFA, rubberduck + Kenney |
| `barracks_ready.wav` (optional) | Barracks completion | CC0 voice "huh/ready" (0.8-1.5s) | HaelDB, LFA (can keep `soldier.wav`) |

### Soft-Deprecated

- `tools/generate_playtest9_placeholder_audio.py` — **Do not use for runtime audio**
  - Procedural synthesis rejected by Helmer
  - Placeholder files (`farm_animal.wav`, `settler_arrive.wav`) deleted from repo
  - Script retained for reference only (marked soft-deprecated)

### Requirements

All runtime audio must be:
- ✅ **Real CC0 recordings** from trusted sources (Freesound, OpenGameArt, Kenney)
- ✅ **Documented provenance** (author, pack, URL, CC0 license)
- ✅ **Processed to spec** (16-bit mono WAV, 44.1kHz, normalized to ≈-1dB)
- ❌ **NO procedural synthesis** for shipped runtime audio

See `docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md` for full sourcing instructions.  
See `assets/settlement/audio/TODO_REQUIRED_CC0_AUDIO.md` for exact file specifications.

---

Last Updated: September 27, 2026 (Playtest.9 - real CC0 required, procedural rejected)
