# TODO: Required CC0 Audio Files

**BLOCKING MERGE**: These real CC0 foley files must be added before PR #5 can be merged.

---

## Missing Files (REQUIRED)

### 1. `farm_animal_complete.wav`
- **Purpose**: Farm building completion sound
- **Character**: Real sheep bleat or farm animal vocalization
- **Duration**: 0.8-1.5 seconds
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **CC0 Sources**: Freesound "sheep bleat CC0", OpenGameArt farm packs
- **Wired**: Yes — event `farm_complete` in audio director

### 2. `settler_arrive_worker.wav`
- **Purpose**: Civilian/worker settler spawn sound
- **Character**: Friendly civilian arrival — footsteps + door, or soft greeting
- **Duration**: 0.6-1.2 seconds
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **CC0 Sources**: qubodup footsteps + rubberduck wood door, or Kenney arrival sounds
- **Wired**: Yes — event `settler_spawn_worker` for all civilian spawns

### 3. `settler_arrive_guard.wav`
- **Purpose**: Military/guard settler spawn sound  
- **Character**: **Prefer CC0 voice grunt/acknowledgment** (HaelDB, LFA) OR armor clink + weapon ready
- **Duration**: 0.8-1.5 seconds
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **CC0 Sources**: HaelDB RPG grunts, LFA Monster Pack, or rubberduck metal + Kenney RPG
- **Wired**: Yes — event `settler_spawn_guard` for soldier training + guard spawns

### 4. `barracks_ready.wav` (OPTIONAL — can keep `soldier.wav`)
- **Purpose**: Barracks building completion sound
- **Character**: **CC0 voice grunt/acknowledgment "huh/ready"** style
- **Current**: Uses `soldier.wav` (Kenney metal jingle) — **replace only if better CC0 voice exists**
- **Duration**: 0.8-1.5 seconds
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **CC0 Sources**: HaelDB RPG Sound Pack grunts, LFA Monster Pack
- **Wired**: Yes — event `barracks_complete`, currently falls back to `soldier.wav`

---

## How to Add These Files

1. **Download or curate** real CC0 recordings from approved sources
2. **Process** to specification (see `docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md`)
3. **Place** in `assets/settlement/audio/` with exact filenames above
4. **Create** Godot `.import` files (or let Godot auto-generate on next import)
5. **Document** in `docs/art/AUDIO_LICENSE_LEDGER.md` with author, pack, URL, license

---

## Approved CC0 Sources

- Freesound.org (filter by CC0 license)
- OpenGameArt.org (CC0 search)
- Kenney.nl (all assets are CC0)
- Existing packs: rubberduck, HaelDB, qubodup, Vehicle tinysized, LFA, etc.

See `docs/art/AUDIO_REQUIREMENTS_PLAYTEST9.md` for full sourcing instructions.

---

## Current Workaround

The code is wired and will attempt to load these files. If files are missing:
- Game will log errors but continue running
- Audio events will silently fail (no sound played)
- Gameplay remains functional

**This is NOT acceptable for merge** — real CC0 audio must be added.

---

## Processing Template

```bash
# Convert to mono 16-bit 44.1kHz WAV
ffmpeg -i input.wav -ac 1 -ar 44100 -sample_fmt s16 output.wav

# Normalize to -1dB peak
ffmpeg -i output.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" normalized.wav

# Add fades (5ms in, 10ms out)
ffmpeg -i normalized.wav -af "afade=t=in:st=0:d=0.005,afade=t=out:st=<duration-0.01>:d=0.01" final.wav
```

---

Last Updated: September 27, 2026
