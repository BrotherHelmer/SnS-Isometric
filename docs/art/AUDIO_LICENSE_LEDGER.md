# Audio License Ledger

This document tracks all audio assets used in Shard & Sovereign and their licenses.

## Settlement SFX (CC0 Original - Playtest.8)

Generated September 27, 2026 by procedural synthesis for playtest.8.
All sounds are original works created specifically for this project.

**License**: CC0 (Public Domain)  
**Author**: Cursor AI Agent (for BrotherHelmer/Shard & Sovereign project)  
**Generation Method**: Python script (`tools/generate_settlement_audio.py`) using wave synthesis  
**Attribution**: Not required (CC0), but credit appreciated

### Files:
- `assets/settlement/audio/ui_click.wav` - UI click/select (0.06s)
- `assets/settlement/audio/build_start.wav` - Construction start hammer (0.08s)
- `assets/settlement/audio/build_complete.wav` - Construction complete chime (0.80s)
- `assets/settlement/audio/delivery.wav` - Resource dropoff (0.15s)
- `assets/settlement/audio/road.wav` - Road construction (0.40s)
- `assets/settlement/audio/woodchop.wav` - Axe chop for lumber work (0.12s)
- `assets/settlement/audio/saw.wav` - Sawmill blade (0.50s)
- `assets/settlement/audio/attack.wav` - Combat hit (0.18s)
- `assets/settlement/audio/tower.wav` - Arrow/projectile launch (0.25s)
- `assets/settlement/audio/enemy.wav` - Enemy spawn (0.60s)
- `assets/settlement/audio/night.wav` - Nightfall warning (0.90s)
- `assets/settlement/audio/soldier.wav` - Military unit ready (0.38s)
- `assets/settlement/audio/destroyed.wav` - Building destruction (1.20s)

**Technical Details**:
- Format: WAV, 16-bit mono, 44.1kHz
- Synthesis: Layered tones, harmonics, ADSR envelopes, filtered noise
- Designed for: Modern colony-sim clarity (Settlers-II-inspired character)

**Reproduction**:
```bash
python3 tools/generate_settlement_audio.py
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
- `ui_click.wav` (presentation version)
- `nightfall_sting.wav`
- `dawn_release.wav`
- `victory_motif.wav`
- `defeat_motif.wav`
- `reckoning_pulse.wav`
- `night_scream.wav`

*(Legacy license status to be documented when sources are verified)*

---

## Previous Placeholder Audio (Replaced in Playtest.8)

Earlier versions of the settlement SFX used thin sine-wave placeholders.
These have been replaced with the layered synthesis described above for improved quality.

---

## Attribution Requirements

### For CC0 Assets (New Settlement SFX):
No attribution required by license. Optional credit:
> Settlement SFX generated for Shard & Sovereign (CC0)

### For Future Third-Party Assets:
When sourcing from Freesound, OpenGameArt, or Kenney:
- Track author, license, and source URL for each file
- Follow CC-BY attribution requirements in credits/README
- Verify compatibility with project's target license

---

Last Updated: September 27, 2026 (Playtest.8)
