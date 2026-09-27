# Audio Requirements for Playtest.9 (REAL CC0 Foley Required)

## Hard Requirements for Merge

Helmer **rejected procedural/synthesized placeholders**. All runtime audio must be:
- **Real CC0 recordings** (Freesound CC0, Kenney, OpenGameArt, etc.)
- **No procedural synthesis** for shipped runtime audio
- **Documented provenance** in `AUDIO_LICENSE_LEDGER.md` with author, pack, URL, license

---

## Required Audio Files

### 1. Farm / Sheep Sounds

#### `farm_animal_complete.wav`
- **Purpose**: Plays when a Farm building completes construction
- **Character**: Single sheep bleat or goat/farm animal vocalization (0.8-1.5s)
- **CC0 Sources**:
  - Freesound.org: "sheep bleat CC0", "goat CC0", "farm animal CC0"
  - OpenGameArt.org: Farm/animal sound packs
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **Install Path**: `assets/settlement/audio/farm_animal_complete.wav`
- **Wired Event**: `farm_complete` (simulation emits when Farm building finishes)

#### `farm_ambient.wav` (OPTIONAL — Nice to have)
- **Purpose**: Light ambient loop/oneshot while Farm exists
- **Character**: Gentle sheep/animal presence, occasional bleats (2-4s, can loop)
- **Can be same as `farm_animal_complete.wav` if suitable**

---

### 2. Settler Spawn Sounds (Per Type — DISTINCT)

Population growth spawns settlers of various types. Each type needs a **distinct** arrival sound based on role:

#### Civilian / Worker Spawn Sounds

**`settler_arrive_worker.wav`** — General laborers/civilians
- **Types**: carrier, woodcutter, miner, farmer, sawyer, baker, clearer (peasant)
- **Character**: Friendly civilian arrival — footsteps + door open, or soft greeting
- **Duration**: 0.6-1.2s
- **CC0 Sources**:
  - Freesound: "door open wood CC0", "footstep CC0", "hello CC0"
  - Kenney Interface Sounds: greeting/arrival sounds
  - Layer: footsteps (qubodup) + wood door creak (rubberduck)
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized
- **Install Path**: `assets/settlement/audio/settler_arrive_worker.wav`

#### Military / Guard Spawn Sounds

**`settler_arrive_guard.wav`** — Soldiers and guards
- **Types**: guard (soldier), ranger (tower guard)
- **Character**: Military acknowledgment — armor clink + weapon ready, or CC0 voice grunt "huh/ready"
- **Duration**: 0.8-1.5s
- **CC0 Sources**:
  - Freesound: "armor clink CC0", "sword sheath CC0", "military grunt CC0"
  - Kenney RPG Audio: armor/weapon sounds
  - HaelDB RPG Sound Pack: NPC grunts (CC0)
  - rubberduck metal sounds + Kenney RPG
- **Prefer**: Real CC0 voice grunt/acknowledgment (HaelDB, LFA) over just metal sounds
- **NO commercial game VO** (no Settlers, AoE, Starcraft, etc.)
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized
- **Install Path**: `assets/settlement/audio/settler_arrive_guard.wav`

#### Founder / Special Spawn (OPTIONAL)

**`settler_arrive_founder.wav`** — Founding arrivals (early game)
- **Character**: More ceremonious/special arrival than regular workers
- **Can be distinct or reuse `settler_arrive_worker.wav` if budget is tight**

---

### 3. Barracks Completion Sound

#### `barracks_ready.wav`
- **Purpose**: Plays when Barracks building completes construction
- **Character**: **CC0 voice grunt/acknowledgment** "huh/ready" style (0.8-1.5s)
- **Current**: Uses `soldier.wav` (Kenney metal jingle) — **replace** if better CC0 voice exists
- **CC0 Sources**:
  - HaelDB RPG Sound Pack: NPC/monster grunts (CC0, OpenGameArt)
  - LFA Monster Sound Pack: short guttural acknowledgments
  - Freesound: "grunt CC0", "ready CC0", "military voice CC0"
- **Requirements**:
  - Real human voice grunt or acknowledgment (not just metallic sound)
  - Short, military/disciplined character
  - **NO copyrighted game VO** (no Age of Empires, Warcraft, Starcraft samples)
- **Specification**: 16-bit mono WAV, 44.1kHz, normalized
- **Install Path**: `assets/settlement/audio/barracks_ready.wav` (or keep `soldier.wav` if good enough)
- **Wired Event**: `barracks_complete`

---

### 4. Additional Atmosphere (If Missing)

#### Work Loop Verification
- ✅ **Lumber Camp chop**: `work_chop.wav` (CC0, playtest.8)
- ✅ **Sawmill saw**: `saw.wav` (CC0, Vehicle tinysized, playtest.8)
- ✅ **Hammer work**: `work_hammer.wav` (CC0, playtest.8)

**ACTION**: Verify these play reliably and audibly at proper volumes. If inaudible, adjust in audio director.

#### Missing Ambient One-Shots (Add if clearly needed)
- **Quarry/mining**: Rock break sounds when quarry works (if `work_hammer.wav` isn't distinct enough)
- **Bakery**: Oven sounds when bakery works (if needed for variety)
- **Farm work**: Shovel/digging sounds distinct from hammer (optional)

**Do NOT add** unless clearly needed for atmosphere — keep scope focused on merge-blocking requirements.

---

## Settler Type → Spawn Sound Mapping

The simulation spawns settlers in `_update_population_growth()`. New settlers start as generic "carrier" type and are assigned roles by `_auto_staff_unstaffed_buildings()`. We need to emit audio based on the **intended role** or default to civilian worker sound.

### Proposed Implementation

**Option 1: Civilian vs Military (Simple)**
- All civilian types (carrier, woodcutter, miner, farmer, sawyer, baker, clearer) → `settler_arrive_worker.wav`
- All military types (guard, ranger) → `settler_arrive_guard.wav`
- Emit event: `settler_spawn_worker` or `settler_spawn_guard` based on context

**Option 2: Role-Specific (If budget allows)**
- Civilian spawn → `settler_arrive_worker.wav`
- Military spawn → `settler_arrive_guard.wav`
- Founder spawn → `settler_arrive_founder.wav` (optional, early game only)

**Recommendation**: Start with Option 1 (civilian vs military). The simulation currently spawns generic carriers, so we'll default to civilian sound unless we can detect military context.

---

## Processing Specifications

All audio files must meet these specs:

```
Format:     WAV
Bit Depth:  16-bit
Channels:   Mono
Sample Rate: 44.1kHz
Peak Level: Normalized to ≈-1dB
Fades:      5-15ms fade-in/out to eliminate clicks
```

### Processing Workflow

```bash
# Convert to mono 16-bit 44.1kHz WAV
ffmpeg -i input.wav -ac 1 -ar 44100 -sample_fmt s16 output.wav

# Normalize to -1dB peak
ffmpeg -i output.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" normalized.wav

# Add fades (5ms in, 10ms out)
ffmpeg -i normalized.wav -af "afade=t=in:st=0:d=0.005,afade=t=out:st=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 normalized.wav | awk '{print $1-0.01}'):d=0.01" final.wav
```

---

## Approved CC0 Source Packs (Playtest.8)

These packs are **already accepted** by Helmer:

- **Kenney** (kenney.nl): Impact Sounds, RPG Audio, Music Jingles, Interface Sounds
- **rubberduck** (OpenGameArt): 100 CC0 metal and wood SFX
- **qubodup** (OpenGameArt): Footsteps (wood/stone/gravel/mud), bamboo stick whooshes
- **Vehicle (Jan Schupke / tinysized)** (OpenGameArt): Fantasy Sound Effects (handsaw, arrow, whoosh)
- **OwlishMedia** (OpenGameArt): 87 Clickety Clips
- **HaelDB** (OpenGameArt): RPG Sound Pack (NPC/monster grunts)
- **LFA** (OpenGameArt): Monster Sound Pack Volume 2
- **Brandon Morris** (OpenGameArt): Completion sounds
- **Robin Lamb** (OpenGameArt): UI Sound Effects (VCSL/VSCO 2 CE)
- **Kresiek The Furry** (OpenGameArt): Dark Stinger 1
- **congusbongus** (OpenGameArt): String and piano horror stings

**Prefer** downloading from these known-good packs when possible.

---

## Sourcing Instructions

### 1. Freesound.org (CC0 Filter)
1. Visit https://freesound.org/
2. Search for required sound (e.g., "sheep bleat")
3. Filter: **License → CC0** (Creative Commons Zero)
4. Download highest-quality WAV or OGG
5. Process to specification (see above)
6. Document: filename, source URL, original artist, license

### 2. OpenGameArt.org (CC0 Search)
1. Visit https://opengameart.org/
2. Search for required sound pack or individual sound
3. Filter: **License → CC0**
4. Download pack or individual file
5. Extract and process to specification
6. Document: filename, pack name, artist, source URL, license

### 3. Kenney.nl (All CC0)
1. Visit https://kenney.nl/assets
2. Browse audio packs (Impact Sounds, RPG Audio, Interface Sounds)
3. Download entire pack (all Kenney assets are CC0)
4. Extract relevant sounds
5. Process to specification
6. Document: filename, pack name, "Kenney", pack URL, CC0

---

## Documentation Requirements

For **every** new audio file added, update `docs/art/AUDIO_LICENSE_LEDGER.md`:

```markdown
### File Name: example_sound.wav
- **Source Pack**: [Pack Name]
- **Artist**: [Artist/Uploader Name]
- **URL**: [Direct link to pack or sound]
- **License**: CC0 (Public Domain)
- **Processing**: Normalized, faded, mono 44.1kHz
- **Character**: [Brief description]
```

Also update `docs/art/AUDIO_PROVENANCE_V3.md` (or create AUDIO_PROVENANCE_V4.md) with detailed per-file attribution.

---

## Audio Policy Reminder (Hard)

**MUST:**
- ✅ Real CC0 or public-domain recordings
- ✅ Documented provenance (author, pack, URL, license)
- ✅ Processed to specification (mono, 44.1kHz, normalized)

**MUST NOT:**
- ❌ Settlers 2 / Amiga / commercial game samples or recreations
- ❌ Copyrighted music or sound effects
- ❌ Procedural synthesis as shipped runtime audio
- ❌ CC-BY or attribution-required licenses for runtime (ok for tools/docs)

**PREFER:**
- 👍 Real curated foley from trusted CC0 packs
- 👍 Known-good sources (Kenney, rubberduck, HaelDB, etc.)
- 👍 Layered real recordings over single synthetic tones

---

## Current Status

### ✅ Already Shipped (Playtest.8, CC0)
- Background music stems (crossfade by game state)
- `work_chop.wav` (lumber camp)
- `saw.wav` (sawmill)
- `work_hammer.wav` (generic work)
- `soldier.wav` (barracks — may replace with voice grunt)

### 🔴 BLOCKING MERGE (Must Add)
- `farm_animal_complete.wav` — Real sheep/farm animal bleat
- `settler_arrive_worker.wav` — Civilian arrival sound
- `settler_arrive_guard.wav` — Military arrival sound (prefer voice grunt)
- `barracks_ready.wav` — Real CC0 voice acknowledgment (or keep `soldier.wav` if good)

### ⚠️ Soft-Deprecated
- `tools/generate_playtest9_placeholder_audio.py` — Do not use for runtime audio

---

## Next Steps

1. **Source real CC0 audio** from Freesound/OpenGameArt/Kenney
2. **Process to specification** (mono, 44.1kHz, normalized, faded)
3. **Install to correct paths** in `assets/settlement/audio/`
4. **Update code** to emit per-type settler spawn events
5. **Document provenance** in `AUDIO_LICENSE_LEDGER.md` and `AUDIO_PROVENANCE_V4.md`
6. **Test in-game** — verify all sounds play at proper volumes and contexts

If cloud environment cannot download directly, **document exact requirements** (URLs, filenames, specifications) and leave TODO paths for manual curation.

---

Last Updated: September 27, 2026 (Playtest.9 — Real CC0 Required)
