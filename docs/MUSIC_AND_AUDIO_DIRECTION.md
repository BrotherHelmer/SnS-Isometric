# Music and Audio Direction

## Identity

The score is an original 90 BPM, eight-bar adaptive loop in D Dorian. Its central contour is D–F–A–G / E–D–C–A. It was written specifically for Shard & Sovereign and is not based on a melody, harmony, arrangement, recording or sample from another game.

The same motif survives the presentation arc:

- Menu and early day: soft plucked-string pulse, warm string bed and a restrained flute-like lead.
- Settlement activity: brighter high plucks and light hand-percussion movement.
- Dusk: low drone, reduced melody and unresolved upper fifths.
- Night: low tom/noise percussion supporting the darker motif.
- Raid and claim pressure: band-limited distorted synthetic rhythm voices and bass-register motif reinforcement.

The arrangement intentionally leaves midrange and transient space for orders, work, gates, weapons and delivery cues.

## Adaptive structure

All five 21.333-second stems share the same 90 BPM sample grid, begin together, loop continuously, and change intensity through volume crossfades rather than restarts.

| Stem | Runtime use |
| --- | --- |
| `score_pastoral_foundation.wav` | Menu, opening and low-intensity day foundation |
| `score_settlement_activity.wav` | Crossfades upward with population/activity |
| `score_dusk_tension.wav` | Enters over the final 90 seconds before night |
| `score_night_percussion.wav` | Becomes prominent at night |
| `score_metal_combat.wav` | Scales with hostile count and peaks during a claim |

Pausing lowers all score stems by 4 dB without stopping or desynchronising them. Muting changes the mix to silence without unloading or restarting a stem. Returning to day crossfades the night and metal layers back down while the shared loop clock continues.

## Soundscape

The settlement uses one looping wind/bird bed and a pool of six attenuated `AudioStreamPlayer2D` emitters. The scheduler chooses a small number of context-valid sounds with cooldowns:

- footsteps while units travel;
- axe/chop around active gatherers;
- hammer around construction;
- Lumen hum at night;
- existing delivery, construction, alarm, gate, attack and impact cues from simulation events.

Night suppresses ordinary civilian work candidates and favours wind, Lumen and combat feedback. The small pool limits simultaneous instances and prevents every workplace from sounding continuously.

## Source and rendering

`tools/generate_presentation_audio.py` is the composition source and renderer. It uses Python’s standard library, mathematical oscillators, deterministic noise and envelope/filter code only. No external samples, model-generated audio, commercial library or third-party recording is used.

- Format: PCM WAV, mono, 16-bit, 22,050 Hz.
- Music grid: 90 BPM, 8 bars, 4/4, 21.333 seconds.
- Loop points: sample 0 to end of file.
- Stem peak ceiling: 0.82 linear (about −1.7 dBFS).
- Short-effect peak ceiling: 0.78 linear (about −2.2 dBFS).
- Runtime mix defaults: Master 80%, Music 70%, Effects 80%, Ambience 65%.

The stems are deliberately mono to keep this small demo package compact and phase-safe. Godot places work effects spatially; music and the broad wind bed remain centred.

## Validation assets

- `artifacts/presentation_pass/motion/music_day_to_night_transition.wav` is an offline reference mix demonstrating the pastoral → dusk → night → metal progression.
- `tests/godot_presentation_smoke.gd` verifies all five stems are loaded together and that music mute does not unload them.
- Screenshot 13 at both supported resolutions records the live value readouts and mute/default controls.

The current demo does not quantise every state-change request to the next bar boundary; it preserves synchronisation and uses smooth crossfades immediately. Bar-queued transitions and a mastered stereo mix remain appropriate later polish tasks.
