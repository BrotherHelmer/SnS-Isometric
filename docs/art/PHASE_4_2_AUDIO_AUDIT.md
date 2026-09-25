# Phase 4.2 Audio Audit

Phase 4.2 keeps `production_audio_director.gd` and the MENU / DAY / DUSK / NIGHT / RAID / RECKONING / VICTORY / DEFEAT state machine. It does **not** treat the Phase 4.1 mathematical score stems as production music.

Default mix: score stems stay at **-80 dB** (emergency fallback only). Day/Night/Raid identity is carried by ambience, Lumen, Wyrd, and one-shot cues.

No new third-party files were imported. Kenney CC0 audio packs were reviewed as a safe source (https://kenney.nl/assets/category:Audio, CC0 1.0 commercial use) but were not downloaded in this pass because the official zip URLs are donation-gated in the fetch path. See `docs/art/AUDIO_LICENSE_LEDGER.md`.

## Classification

A — acceptable indie production quality  
B — usable temporary  
C — demo-quality / replace

| Clip / stem | Role | Class | Notes |
| --- | --- | --- | --- |
| `score_pastoral_foundation.wav` | Menu / day music | C | Unused in default mix. Oscillator bed. Fallback only. |
| `score_settlement_activity.wav` | Day activity layer | C | Unused in default mix. |
| `score_dusk_tension.wav` | Dusk music | C | Unused in default mix. |
| `score_night_percussion.wav` | Night music | C | Unused in default mix. |
| `score_metal_combat.wav` | Raid / Reckoning music | C | Unused in default mix. Must not loop as an alarm. |
| `settlement_wind_birds.wav` | Global ambience | C | Generated wind/birds. Day bed at −11 dB; night ducked to −28 dB so night is not “day −8 dB”. Replace with recorded forest. |
| `lumen_hum.wav` | Night Lumen | B | Thin synth warmth. Usable until a recorded fire/room tone exists. |
| `wyrd_drone.wav` | Wyrd family | C | Still reads as an oscillator test. Keep the family routing; replace the sample. |
| `work_chop.wav` | Lumber spatial | C | Generated axe. Functional, not tactile. |
| `work_hammer.wav` | Construction / quarry | C | Generated impact. |
| `footstep.wav` | Travel | C | Not in the 4.2 default mix. |
| `ui_click.wav` | UI | C | Generated click. Kenney Interface Sounds is the preferred replace. |
| `nightfall_sting.wav` | Dusk sting | B | Short cue. Better than a looping bed. |
| `dawn_release.wav` | Dawn | B | Short cue. |
| `victory_motif.wav` | Victory | C | Generated motif. |
| `defeat_motif.wav` | Defeat | C | Generated motif. |
| `reckoning_pulse.wav` | Reckoning enter | B | One-shot, not a loop. |
| `enemy.wav` | Raid warning | B | Legacy one-shot. Raid onset uses this, not the metal stem. |
| `night.wav` | Night event | B | Legacy. |
| `attack.wav` | Melee | B | Legacy impact. |
| `tower.wav` | Projectile | B | Legacy. Timing still matches impact-on-hit. |
| `build_start.wav` / `build_complete.wav` | Construction | B | Legacy. |
| `delivery.wav` / `road.wav` / `soldier.wav` / `destroyed.wav` | Misc SFX | B | Legacy, unchanged. |
| `ambience.wav` / `music.wav` | Older settlement loops | B | Not the Phase 4.1 director default. |

## Soundtrack gap

There is **no licensed production score** in the default player mix.

Safe next sources (verify License.txt before import):

- Kenney Interface Sounds, Impact Sounds, RPG Audio — CC0 1.0, commercial-game-safe.
- Recorded CC0 forest day / night beds (birds, wind, insects) from a ledgered pack, not YouTube rips.

Until those exist, the correct default is: **quiet ambience + event cues**, not another generated “score”.

## Manual listening pass

An automated state test (`tests/phase4_2_audio_evidence.gd`) confirmed:

- menu / day / dusk / night / raid states resolve
- placeholder score stems are **not** in the active mix
- raid plays the `enemy` one-shot on enter

A headphone/speaker quality pass was **not** completed in this environment. Subjective grades below are architecture-informed, not a human listen:

| State | Subjective |
| --- | --- |
| DAY | Alive enough to be a bed, still generated birds. Not a buyable pastoral score. |
| NIGHT | Distinct from day (birds ducked, Wyrd/Lumen up). Still thin. |
| RAID | Instant cue, no looping metal bed. Warning is the strongest moment. |
| RECKONING | Pulse one-shot + Wyrd up. Not a climax score. |

**Audio content is not a clean quality PASS.** Architecture and mix policy are PASS.
