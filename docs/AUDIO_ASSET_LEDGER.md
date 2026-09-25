# Audio Asset Ledger

## Presentation score and soundscape

All assets in this table are original repository-generated audio. Copyright is held by the Shard & Sovereign project owner. No attribution or third-party licence is required.

| Asset | Purpose | Duration / format | Source | Licence / provenance |
| --- | --- | --- | --- | --- |
| `assets/settlement/audio/presentation/score_pastoral_foundation.wav` | Menu/day melodic foundation | 21.333 s; mono PCM16 22.05 kHz | `tools/generate_presentation_audio.py` | Original mathematical synthesis; project-owned |
| `assets/settlement/audio/presentation/score_settlement_activity.wav` | Settlement activity layer | 21.333 s; mono PCM16 22.05 kHz | Same renderer | Original mathematical synthesis; project-owned |
| `assets/settlement/audio/presentation/score_dusk_tension.wav` | Dusk drone/tension | 21.333 s; mono PCM16 22.05 kHz | Same renderer | Original mathematical synthesis; project-owned |
| `assets/settlement/audio/presentation/score_night_percussion.wav` | Night percussion | 21.333 s; mono PCM16 22.05 kHz | Same renderer | Original deterministic-noise synthesis; project-owned |
| `assets/settlement/audio/presentation/score_metal_combat.wav` | Raid/claim synthetic metal layer | 21.333 s; mono PCM16 22.05 kHz | Same renderer | Original oscillator/distortion synthesis; project-owned |
| `assets/settlement/audio/presentation/settlement_wind_birds.wav` | Looping environmental bed | 8.0 s; mono PCM16 22.05 kHz | Same renderer | Original deterministic-noise and oscillator synthesis; project-owned |
| `assets/settlement/audio/presentation/work_chop.wav` | Positional axe cue | 0.42 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/work_hammer.wav` | Positional construction cue | 0.32 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/footstep.wav` | Positional travel cue | 0.18 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/lumen_hum.wav` | Night Lumen cue | 3.0 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/wyrd_drone.wav` | Wyrd identity drone | 6.0 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/ui_click.wav` | UI click | 0.16 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/nightfall_sting.wav` | Nightfall sting | 1.6 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/dawn_release.wav` | Dawn release | 2.4 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/victory_motif.wav` | Victory motif | 1.6 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/defeat_motif.wav` | Defeat motif | 1.8 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `assets/settlement/audio/presentation/reckoning_pulse.wav` | Reckoning pulse | 3.2 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |
| `artifacts/presentation_pass/motion/music_day_to_night_transition.wav` | QA reference transition mix; not shipped runtime content | 21.333 s; mono PCM16 22.05 kHz | Same renderer | Original synthesis; project-owned |

## Runtime/import notes

- Godot imports every presentation WAV into the Windows export; the source WAVs total under 5.2 MB.
- Music loop mode is set at runtime to forward loop. All five stems have equal sample counts and aligned first samples.
- No file has leading silence beyond its intentional musical envelope.
- The generator normalises stems to a maximum 0.82 linear peak and effects to 0.78, leaving headroom for the adaptive mix.
- The six-emitter positional pool applies distance attenuation and concurrency limits to work sounds.
- Existing legacy event cues elsewhere under `assets/settlement/audio/` predate this pass and remain covered by the repository’s existing `docs/THIRD_PARTY_NOTICES.txt`; they are not represented as newly authored presentation-score assets here.

## Rebuild

Run:

```powershell
python .\tools\generate_presentation_audio.py
```

Then open/import the project once in Godot before exporting. The renderer is deterministic: the same source revision creates the same musical and sound-effect content.
