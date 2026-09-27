# Audio Requirements for Playtest.9

## New CC0 Audio Files Needed

This document describes the additional CC0/public-domain audio files required for playtest.9 to address Helmer's audio feedback.

### Required Audio Files

#### 1. Farm Animal Sound (`farm_animal.wav`)
- **Purpose**: Plays when a Farm building completes construction
- **Character**: Sheep bleating or general farm animal ambience
- **Duration**: 0.8-1.2 seconds
- **CC0 Sources to Check**:
  - Freesound.org: Search "sheep bleat CC0" or "farm animals CC0"
  - OpenGameArt.org: Farm/animal sound packs
  - Kenney.nl: Animal Sound Pack (if available)
- **Processing**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **Install Path**: `assets/settlement/audio/farm_animal.wav`

#### 2. Settler Arrival Sound (`settler_arrive.wav`)
- **Purpose**: Plays when a new settler spawns/arrives at the settlement
- **Character**: Friendly arrival acknowledgment or footsteps + door open
- **Duration**: 0.6-1.0 seconds
- **CC0 Sources to Check**:
  - Freesound.org: Search "hello CC0", "arrival CC0", or "door open CC0"
  - OpenGameArt.org: Greeting/acknowledgment sound packs
  - Existing layered foley: footsteps + wood door creak
- **Processing**: 16-bit mono WAV, 44.1kHz, normalized to ≈-1dB
- **Install Path**: `assets/settlement/audio/settler_arrive.wav`

### Already Implemented (No New Files Needed)

The following audio requirements are satisfied by **existing** CC0 audio:

- ✅ **Background music**: Existing stems (`score_pastoral_foundation.wav`, `score_settlement_activity.wav`, etc.) already provide looping ambient music that fades based on game state
- ✅ **Woodcutting sounds**: `assets/settlement/audio/presentation/work_chop.wav` (CC0, documented in AUDIO_LICENSE_LEDGER.md)
- ✅ **Sawmill sounds**: `assets/settlement/audio/saw.wav` (CC0, documented in AUDIO_LICENSE_LEDGER.md)
- ✅ **Barracks completion**: `assets/settlement/audio/soldier.wav` (CC0 military acknowledgment, documented in AUDIO_LICENSE_LEDGER.md)

### Gameplay Integration Status

All audio events are **wired and functional** as of playtest.9:

1. **Farm completion** → triggers `farm_complete` audio event → plays `farm_animal.wav`
2. **Barracks completion** → triggers `barracks_complete` audio event → plays `soldier.wav`
3. **Settler spawn** → triggers `settler_spawn` audio event → plays `settler_arrive.wav`
4. **Sawmill work** → triggers "saw" work sound → plays `saw.wav` (differentiated from lumber camp chop)
5. **Lumber camp work** → triggers "chop" work sound → plays `work_chop.wav`
6. **Background music** → existing stem system crossfades pastoral/activity/dusk/night/raid music

The only missing pieces are the two new audio files listed above.

### Sourcing Instructions

1. Visit Freesound.org and filter by **CC0 license** (not CC-BY, which requires attribution)
2. Search for the required sounds
3. Download high-quality WAV or FLAC files
4. Process to specification:
   ```bash
   # Convert to 16-bit mono 44.1kHz WAV
   ffmpeg -i input.wav -ac 1 -ar 44100 -sample_fmt s16 output.wav
   # Normalize to -1dB peak
   ffmpeg -i output.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11" normalized.wav
   ```
5. Place in correct paths (see above)
6. Update `docs/art/AUDIO_LICENSE_LEDGER.md` with:
   - File name
   - Source URL
   - Original artist/uploader
   - License (CC0)
   - Any processing applied

### Alternative: Temporary Placeholder Approach

If CC0 sourcing takes time, create minimal placeholder audio:
- **farm_animal.wav**: Short tone or existing layered foley (e.g., wood creak + gentle thud)
- **settler_arrive.wav**: Existing footstep sound or short bell/chime

These placeholders keep the game playable while proper CC0 audio is sourced.

### Audio Policy Reminder

**Hard requirement**: All runtime audio must be CC0 or public domain. No:
- Settlers 2 / Amiga / commercial game samples
- Copyrighted music or sound effects
- CC-BY (attribution-required) assets in runtime (ok for tools/docs)

Document all sources in `AUDIO_LICENSE_LEDGER.md` and `AUDIO_PROVENANCE_V3.md`.

---

Last Updated: September 27, 2026 (Playtest.9 preparation)
