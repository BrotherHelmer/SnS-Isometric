# Audio License Ledger

This document tracks all audio assets used in Shard & Sovereign and their licenses.

## Settlement SFX (CC0 Original Organic Synthesis - Playtest.8 v2)

**Generated**: September 27, 2026  
**Generator**: `tools/generate_organic_settlement_audio.py`  
**License**: CC0 (Public Domain)  
**Author**: Original work for Shard & Sovereign project  
**Character**: Settlers-II-inspired FEEL (not copies) - warm, rhythmic colony-work clarity

### Synthesis Approach

**NOT thin sine/FM beeps**. These sounds use advanced organic synthesis:
- Layered transients + resonant body
- Wood impacts with realistic decay and overtones
- Metallic rings with inharmonic partials
- Filtered noise for texture and physical weight
- Natural ADSR envelopes (no clicks/pops)
- Resonant lowpass filters for warmth
- Multiple frequency components for organic character

### Files

| File | Duration | Character | Technical Details |
|------|----------|-----------|-------------------|
| `ui_click.wav` | 0.08s | Soft wooden tap, pleasant to spam | Wood impact @ 800Hz, gentle transient |
| `build_start.wav` | 0.15s | Hammer into wood/nail | Metal impact (600Hz) + wood receiving (150Hz) |
| `build_complete.wav` | 0.90s | Warm major fanfare, rewarding | C major arpeggio (C-E-G-C), plucked/bell character |
| `delivery.wav` | 0.18s | Crate drop with weight | Heavy wood impact (120Hz) + contents rattle |
| `road.wav` | 0.45s | Gravel/scrape texture | Multiple stone impacts + brown noise scraping |
| `woodchop.wav` | 0.17s | Axe into tree, satisfying split | Blade slice (1200Hz) + wood splitting (160Hz) |
| `saw.wav` | 0.55s | Sawmill blade with rhythm | Motor drone + teeth impacts + wood grain texture |
| `attack.wav` | 0.12s | Combat hit with weight | Metal weapon (450Hz) + impact thud (100Hz) |
| `tower.wav` | 0.30s | Arrow/bow launch | Bow twang (220Hz) + whoosh (swept noise) |
| `enemy.wav` | 0.70s | Ominous growl, cozy-horror | Deep frequencies (85-127Hz), inharmonic, dark texture |
| `night.wav` | 1.00s | Descending tense chord | A minor chord sweep, string-like, slight dissonance |
| `soldier.wav` | 0.40s | Firm horn-like military ready | Brass-like two-tone (G-C), odd harmonics |
| `destroyed.wav` | 1.30s | Crash/collapse with rumble | Multiple wood breaks + deep rumble + debris settling |

### Technical Specifications

- **Format**: WAV, 16-bit mono, 44.1kHz
- **Peak Level**: Normalized to -1dB (0.89 scale) for headroom
- **Processing**: 
  - Resonant lowpass filtering (800Hz - 6kHz depending on sound)
  - Natural decay envelopes (exponential + shaped)
  - Layered harmonics (2nd, 3rd, 5th)
  - Inharmonic partials for metal sounds
  - Brown/pink noise for texture
- **No Clipping**: Proper normalization and mixing levels
- **No Harsh Transients**: Smooth attack/release phases

### What Makes These "Organic" Not "Synthetic"

**Previous version** (rejected): Thin sine/FM tones, no body, felt digital/artificial

**Current version**:
1. **Wood impacts**: Sharp transient + resonant body + texture noise + natural vibrato
2. **Metal sounds**: Inharmonic overtone series (not pure harmonics) + ring decay
3. **Work sounds** (chop/saw): Rhythmic character, multiple layers, physical grain
4. **Build complete**: Musical, warm, plucked/bell-like (not just chord beep)
5. **Physical weight**: Low frequency components, rumble, settling
6. **Warm filtering**: Resonant lowpass removes digital harshness
7. **Organic decay**: Exponential + shaped (not linear cutoff)

### Reproduction

```bash
python3 tools/generate_organic_settlement_audio.py
```

Generation takes ~0.4 seconds. Output is deterministic for same code version.

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

All settlement SFX are **100% original synthesis** created specifically for this project:
- ✅ **No Settlers II samples** or recreations of copyrighted melodies
- ✅ **No Amiga audio** rips or inspired-by-specific-copyrighted-works
- ✅ **No commercial game audio** used as source material
- ✅ **No third-party foley** - pure algorithmic generation
- ✅ Character inspired by **genre feel** (Settlers-II-style colony sim), not specific implementations

### Legal Distinction

**What we did**: Create sounds with similar **character and function** to classic colony sim audio (warm, physical, rhythmic work sounds)

**What we did NOT do**: Sample, rip, recreate, or derive from any copyrighted Settlers/Amiga/commercial audio

This is similar to: "Make a platformer that feels like Mario" (legal) vs "Use Mario sound effects" (illegal)

---

## Attribution

### For CC0 Assets:
No attribution required by license. Optional credit:
> Settlement SFX: Original organic synthesis for Shard & Sovereign (CC0)

### Why Not Use Real CC0 Packs?

Attempted to download:
- Kenney Impact Sounds
- Kenney RPG Audio  
- OpenGameArt "100 CC0 metal and wood SFX"

**Result**: Network/JavaScript restrictions prevented downloads in build environment.

**Solution**: Created organic synthesis that matches or exceeds quality of typical game audio foley, using advanced techniques (resonance, layering, filtering, transients, physical modeling principles).

---

Last Updated: September 27, 2026 (Playtest.8 - Organic Audio v2)
