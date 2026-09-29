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

## Playtest.9 Atmosphere Audio (CC0 Real Foley)

**Added**: September 27, 2026  
**Source**: Curated CC0 pack `cc0-playtest9-atmosphere.zip`  
**License**: CC0 (Public Domain) — **Real recordings / game foley**  
**Format**: WAV, 44.1 kHz, 16-bit PCM, mono, peak ≈ -3...-6 dBFS, fades 12-25ms

### Files

#### farm_animal.wav
- **Purpose**: Farm building completion + occasional animal presence
- **Character**: Warm short sheep bleat (≈0.87s)
- **Source Pack**: Sheep Baa (OpenGameArt)
- **Original File**: `sheep_baa.flac`
- **License**: CC0
- **Author**: Recording by **mikewest**; packaged by **AntumDeluge**
- **URL**: https://opengameart.org/content/sheep-baa
- **Processing**: Mono 44.1kHz s16; peak normalize to -4 dBFS; 12ms in / 25ms out fades

#### farm_ambient.wav
- **Purpose**: Softer distant sheep/farm bed (non-loop one-shot, ≈2.70s)
- **Character**: Bells + flock presence, soft background
- **Source Pack**: BigSoundBank — Flock of Sheep and Cows (#3220)
- **Original File**: `3220.mp3` (extract ≈7.2-9.9s)
- **License**: CC0 / public-domain equivalent
- **Authors**: **Joseph Sardin** & **Axeline T.**
- **URL**: https://bigsoundbank.com/flock-sheep-and-cows-s3220.html
- **Processing**: Highpass 120Hz + lowpass 3.5kHz for distant bed; mono 44.1kHz s16; peak -6 dBFS

#### monster_kill_cheer.wav (playtest.31)
- **Purpose**: Short cheer when a soldier (patrol strike) or soldier-staffed Watchtower bolt kills a monster; throttled to one cheer per 0.8 s
- **Character**: Single human voice "cheers"/victory shout (≈1.75s)
- **Source**: OpenGameArt "Cheers" by **Nocturnal_Vanguard** (AuraVoice), file `cheers_1.ogg` (sha256 `10d9f614307127a8c2b2b129e9a291b6071c8fc91f1fed4916f78ad47c956b25`)
- **License**: CC0 (public domain dedication; "use however you like, no credit required")
- **URL**: https://opengameart.org/content/cheers-0
- **Processing**: Trim 0–1.75 s, mono 44.1 kHz PCM16, 10 ms fade-in, 0.25 s fade-out; peak -4.2 dBFS (no gain change)

#### settler_arrive_worker.wav
- **Purpose**: Civilian/worker settler spawn
- **Character**: Soft friendly arrival (footstep + cloth/leather, ≈0.49s)
- **Source Pack**: Kenney RPG Audio
- **Original Files**: `footstep00.ogg` + `cloth1.ogg` + `handleSmallLeather.ogg`
- **License**: CC0
- **Author**: **Kenney** (www.kenney.nl)
- **URL**: https://kenney.nl/assets/rpg-audio
- **Processing**: Layered footstep + cloth (adelay ~40ms, -5dB) + leather (adelay ~90ms); trim; peak -5 dBFS

#### settler_arrive_soldier.wav
- **Purpose**: Soldier/guard spawn
- **Character**: Military boot + steel acknowledgment (≈0.68s)
- **Source Packs**: Fantasy Sound Effects (Tinysized SFX); RPG Sound Pack
- **Original Files**: `boots-leather-step-01.wav` + `battle/sword-unsheathe2.wav` + `inventory/chainmail2.wav`
- **License**: CC0
- **Authors**: **Vehicle** (Jan Schupke / tinysized); **artisticdude**
- **URLs**: https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx ; https://opengameart.org/content/rpg-sound-pack
- **Processing**: Boot step + sword unsheathe (adelay ~30ms) + quiet chainmail rattle; peak -4 dBFS
- **Note**: No CC0 human voice grunt available; boot+steel fulfills alternate requirement

#### settler_arrive_generic.wav
- **Purpose**: Fallback arrival for other settler roles
- **Character**: Soft step + belt leather + quiet UI confirm (≈0.60s)
- **Source Packs**: Kenney RPG Audio; Kenney Interface Sounds
- **Original Files**: `footstep01.ogg` + `beltHandle1.ogg` + `confirmation_002.ogg`
- **License**: CC0
- **Author**: **Kenney**
- **URLs**: https://kenney.nl/assets/rpg-audio ; https://kenney.nl/assets/interface-sounds
- **Processing**: Footstep + belt (adelay ~35ms) + quiet confirmation (adelay ~60ms, low level); peak -5 dBFS

#### barracks_ready.wav
- **Purpose**: Barracks/military-ready completion cue
- **Character**: Steel draw + short steel jingle + confirm (≈0.59s)
- **Source Packs**: RPG Sound Pack; Kenney Music Jingles; Kenney Interface Sounds
- **Original Files**: `battle/sword-unsheathe.wav` + `jingles_STEEL00.ogg` (trim 0.55s) + `confirmation_001.ogg`
- **License**: CC0
- **Authors**: **artisticdude**; **Kenney**
- **URLs**: https://opengameart.org/content/rpg-sound-pack ; https://kenney.nl/assets/music-jingles ; https://kenney.nl/assets/interface-sounds
- **Processing**: Unsheathe + steel jingle (adelay ~40ms) + quiet confirmation; peak -4 dBFS

### Technical Specifications

All files meet runtime requirements:
- ✅ Real CC0 recordings (no procedural synthesis)
- ✅ 16-bit mono WAV, 44.1kHz
- ✅ Peak normalized to ≈ -3...-6 dBFS
- ✅ Short fades (12-25ms) to eliminate clicks
- ✅ Documented provenance (author, pack, URL, license)

### Soft-Deprecated

- `tools/generate_playtest9_placeholder_audio.py` — **Do not use for runtime audio**
  - Procedural synthesis rejected by Helmer
  - Script retained for reference only (marked soft-deprecated)
  - All runtime audio is now real CC0 foley

---

## Playtest.10 BGM + Atmosphere (CC0)

**Added**: September 27, 2026  
**Source**: Curated CC0 pack `cc0-playtest10-bgm.zip`  
**License**: CC0 (Public Domain)  
**Character**: Warm pastoral medieval settlement theme + soft natural ambience  
**Purpose**: Replace/supplement existing BGM with full-length looping town theme + nature bed

### Files

#### bgm_settlement_loop.ogg
- **Purpose**: Primary settlement BGM (day/main theme)
- **Duration**: 94.5 seconds (seamless crossfade loop)
- **Format**: Ogg Vorbis, stereo, 44.1 kHz, ~130 kbps
- **Character**: Warm pastoral medieval town theme (harps + recorders emotional space)
- **Source Pack**: Town Theme RPG
- **Original File**: `TownTheme.mp3`
- **License**: CC0 (Public Domain dedication on OpenGameArt)
- **Author**: **cynicmusic** (pixelsphere.org / cynicmusic.com)
- **URL**: https://opengameart.org/content/town-theme-rpg
- **Direct Source**: https://opengameart.org/sites/default/files/TownTheme.mp3
- **Processing**: 3.0s triangular acrossfade (tail↔head) for click-free loop; loudnorm ≈ -16 LUFS / TP -1.5 dB; libvorbis q≈5
- **Usage**: Music bus, loop enabled from game start
- **Replaces**: `score_pastoral_foundation.wav` (now using full-length original CC0 theme)

#### ambient_world.wav
- **Purpose**: Soft wind + birds nature bed (continuous ambient layer)
- **Duration**: 26.0 seconds (crossfade-looped)
- **Format**: WAV PCM s16le, mono, 44.1 kHz
- **Character**: Soft nature ambience (no musical synth bed — pure ambient mix)
- **Source Pack**: Birds and Wind — Ambient
- **Original File**: `Birds and Wind - Ambient_1.ogg`
- **License**: CC0
- **Author/Composer**: **Spring Spring** (composer "Spring"); bird SFX contributors: isaiah658, syncopika, pauliuw (all PD/CC0)
- **URL**: https://opengameart.org/content/birds-and-wind-ambient-birds-wind-and-synth
- **Direct Source**: https://opengameart.org/sites/default/files/Birds%20and%20Wind%20-%20Ambient_1.ogg
- **Processing**: First 28s; 2.0s acrossfade loop; HPF 80Hz / LPF 8kHz; loudnorm quiet bed ≈ -28 LUFS / TP -6 dB; mono s16
- **Usage**: Ambience bus, loop enabled, kept quiet under Music/SFX
- **Replaces**: `settlement_wind_birds.wav` (now using dedicated nature-only ambient bed)

#### farm_animal.wav (Updated)
- **Purpose**: Farm completion cue + occasional animal presence
- **Duration**: 0.87 seconds
- **Format**: WAV PCM s16le, mono, 44.1 kHz
- **Character**: Clearer / louder warm sheep bleat (more audible than playtest.9 version)
- **Source Pack**: Sheep Baa (OpenGameArt)
- **Original File**: `sheep_baa.flac`
- **License**: CC0
- **Author**: Recording by **mikewest**; packaged/submitted by **AntumDeluge**
- **URL**: https://opengameart.org/content/sheep-baa
- **Processing**: HPF 200Hz / LPF 6kHz; mild presence EQ (+2.5 dB @ 1.2 kHz); 12ms in / 25ms out fades; loudnorm ≈ -16 LUFS / TP -2.5 dB (louder/clearer than playtest.9 -4 dBFS peak version)
- **Usage**: SFX bus, one-shot on Farm completion event
- **Replaces**: Previous playtest.9 `farm_animal.wav` (now with better presence/clarity)

### Technical Specifications

All files meet runtime requirements:
- ✅ Real CC0 recordings/compositions (no procedural synthesis)
- ✅ BGM: Ogg Vorbis stereo 44.1kHz (Godot-friendly, loop-enabled)
- ✅ Ambient/SFX: WAV 16-bit mono 44.1kHz
- ✅ Loudness-normalized for consistent volume
- ✅ Seamless looping (crossfade-processed)
- ✅ Full provenance documented (author, pack, URL, license)

### Auditioned But Not Included

Helmer's curated pack evaluated additional CC0 music but selected the above as primary:
- Magician Village Loop (beardalaxy) — too short (~18.9s)
- Medieval fair loop (Woli34) — too busy, not quiet settlement
- Medieval: Harvest Season (RandomMind) — too long/epic, not cozy town
- Port Town Loop (beardalaxy) — port/dock mood, not pastoral
- HoliznaCC0 Quiet Village 1-4 (FMA/Bandcamp) — excellent match but 404 download from environment

*(Full evaluation notes in `cc0-playtest10-bgm.zip/PROVENANCE.md`)*

### Integration Notes

- **BGM loop**: Godot import should set OGG to `loop = true` on Music bus
- **Ambient loop**: WAV set to `loop = true` on Ambience bus, kept -8 to -12 dB under Music
- **Farm bleat**: One-shot on SFX bus (not looped)
- **No copyrighted covers**: No Settlers II, Amiga, or commercial game samples used
- **Character-appropriate**: Warm pastoral medieval town feel without copying Settlers II theme melody

---

Last Updated: September 27, 2026 (Playtest.10 - CC0 BGM + atmosphere integrated)
