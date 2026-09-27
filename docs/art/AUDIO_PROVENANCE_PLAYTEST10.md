# Shard & Sovereign — CC0 Playtest.10 BGM + Atmosphere Provenance

All output files are curated/edited from **CC0** (Creative Commons Zero / public domain dedication) sources.
**No Settlers II, Amiga, commercial game samples, or SoundCloud covers of copyrighted themes.**

**Target formats:** Music → Ogg Vorbis stereo 44.1 kHz (Godot-friendly). SFX/ambient → WAV 44.1 kHz 16-bit PCM mono.
**Build date:** 2026-09-27 (Europe/Copenhagen)

---

## bgm_settlement_loop.ogg

| Field | Value |
| --- | --- |
| Character | Warm pastoral medieval town / settlement theme (harps + recorders emotional space; original, not a Settlers cover) |
| Duration | ≈ 94.5 s (seamless crossfade-loop body; loops cleanly end→start) |
| Format | Ogg Vorbis, stereo, 44.1 kHz, ~130 kbps |
| Source pack / title | Town Theme RPG |
| Original file | `TownTheme.mp3` |
| License | **CC0** (Public Domain dedication on OpenGameArt) |
| Author | **cynicmusic** (pixelsphere.org / cynicmusic.com) |
| Source URL | https://opengameart.org/content/town-theme-rpg |
| Direct source file | https://opengameart.org/sites/default/files/TownTheme.mp3 |
| Processing | 3.0 s triangular acrossfade of track tail↔head to produce a click-free loop body (output length = original − 3 s); loudnorm ≈ −16 LUFS / TP −1.5 dB; encoded libvorbis q≈5 |

---

## ambient_world.wav

| Field | Value |
| --- | --- |
| Character | Soft wind + birds nature bed (no musical synth bed — ambient-only mix) |
| Duration | ≈ 26.0 s (≤30 s; crossfade-looped) |
| Format | WAV PCM s16le, mono, 44.1 kHz |
| Source pack / title | Birds and Wind — Ambient (track: “Birds and Wind - Ambient”) |
| Original file | `Birds and Wind - Ambient_1.ogg` |
| License | **CC0** |
| Author / composer | **Spring Spring** (composer “Spring”); bird SFX contributors noted on page: isaiah658, syncopika, pauliuw (all PD/CC0 as stated on OGA) |
| Source URL | https://opengameart.org/content/birds-and-wind-ambient-birds-wind-and-synth |
| Direct source file | https://opengameart.org/sites/default/files/Birds%20and%20Wind%20-%20Ambient_1.ogg |
| Processing | Take first 28 s; 2.0 s acrossfade loop; HPF 80 Hz / LPF 8 kHz; loudnorm quiet bed ≈ −28 LUFS / TP −6 dB; mono 44.1 kHz s16 |

---

## farm_animal.wav

| Field | Value |
| --- | --- |
| Character | Clearer / slightly louder warm sheep bleat (farm complete + occasional animal presence) |
| Duration | ≈ 0.87 s |
| Format | WAV PCM s16le, mono, 44.1 kHz |
| Source pack | Sheep Baa (OpenGameArt) |
| Original file | `sheep_baa.flac` (cached under `/workspace/sns-audio/packs/sheep/`) |
| License | **CC0** |
| Author / submitter | Recording by **mikewest**; packaged/submitted by **AntumDeluge** |
| Source URL | https://opengameart.org/content/sheep-baa |
| Processing | HPF 200 / LPF 6k; mild presence EQ (+2.5 dB @ 1.2 kHz); 12 ms in / 25 ms out fades; loudnorm ≈ −16 LUFS / TP −2.5 dB (louder/clearer than playtest.9 −4 dBFS peak version) |

---

## Auditioned but not shipped in this zip

| Candidate | License | Why not primary |
| --- | --- | --- |
| Magician Village Loop (beardalaxy) | CC0 | Only ≈18.9 s — kept as local cache under `packs/music/magician_village.ogg` for optional stem use |
| Medieval fair loop (Woli34) | CC0 | Only ≈15.5 s; more “busy fair” than quiet settlement |
| Medieval: Harvest Season (RandomMind) | CC0 | ≈214 s (over 180 s budget); more epic/orchestral than cozy town |
| Port Town Loop (beardalaxy) | CC0 | Port/dock mood, not pastoral settlement |
| HoliznaCC0 Quiet Village 1–4 (FMA/Bandcamp) | CC0 1.0 | Excellent mood match; FMA direct download returned 404 from this environment — not included rather than risk unverified bytes |
| Kenney Music Jingles (cached) | CC0 | Short stingers only (~few seconds), not settlement BGM length |

---

## Local packs consulted

- `/workspace/sns-audio/packs/kenney_jingles/` (Kenney Music Jingles — CC0; too short for BGM)
- `/workspace/sns-audio/packs/sheep/` (Sheep Baa + BigSoundBank flock from playtest.9)
- Newly cached under `/workspace/sns-audio/packs/music/`: TownTheme, Magician Village, Medieval fair, Harvest Season, Port Town, Birds and Wind Ambient

## Gaps / honesty

- Primary BGM is a **full arranged town theme** made loopable via crossfade, not a factory-seamless infinite stem. Godot should set the OGG to **loop** on the Music bus from scene start.
- `ambient_world` is intentionally quiet (−28 LUFS) so it sits under BGM; raise bus gain if needed.
- No copyrighted covers or commercial-game ripped samples were used.
