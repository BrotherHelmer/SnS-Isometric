# Shard & Sovereign — CC0 Playtest.9 Atmosphere SFX Provenance

All output files are curated/edited from **CC0** (Creative Commons Zero / public domain dedication) **real recordings / game foley**.
No Settlers, Amiga, or commercial game samples. **No synthesis / procedural sine stubs.**

**Target format:** WAV, 44.1 kHz, 16-bit PCM, mono, peak ≈ −3…−6 dBFS, short fades (≈12–25 ms) to kill clicks.

**Build date:** 2026-09-27 (Europe/Copenhagen)

---

## farm_animal.wav

| Field | Value |
| --- | --- |
| Character | Warm short sheep bleat (farm complete + occasional ambient animal presence) |
| Duration | ≈ 0.87 s |
| Source pack | Sheep Baa (OpenGameArt) |
| Original file | `sheep_baa.flac` |
| License | CC0 |
| Author / submitter | Recording by **mikewest**; packaged/submitted by **AntumDeluge** |
| Source URL | https://opengameart.org/content/sheep-baa |
| Processing | Mono 44.1 kHz s16; light peak normalize to −4 dBFS; 12 ms in / 25 ms out fades; character of real bleat preserved |

---

## farm_ambient.wav

| Field | Value |
| --- | --- |
| Character | Softer distant sheep/farm bed (bells + flock presence), short non-loop one-shot bed |
| Duration | ≈ 2.70 s |
| Source pack | BigSoundBank — Flock of Sheep and Cows (#3220) |
| Original file | `3220.mp3` (full download from BigSoundBank UPLOAD/mp3) |
| License | CC0 / public-domain equivalent (stated on BigSoundBank) |
| Author | **Joseph Sardin** & **Axeline T.** |
| Source URL | https://bigsoundbank.com/flock-sheep-and-cows-s3220.html |
| Processing | Extract ≈7.2–9.9 s; highpass 120 Hz + lowpass 3.5 kHz for distant softer bed; mono 44.1 kHz s16; peak −6 dBFS; fades |

---

## settler_arrive_worker.wav

| Field | Value |
| --- | --- |
| Character | Soft friendly civilian/worker arrival (footstep + cloth/leather) |
| Duration | ≈ 0.49 s |
| Source pack | Kenney RPG Audio |
| Original files | `footstep00.ogg` + `cloth1.ogg` + `handleSmallLeather.ogg` |
| License | CC0 |
| Author | **Kenney** (www.kenney.nl) |
| Source URL | https://kenney.nl/assets/rpg-audio |
| Processing | Layer footstep (primary) + cloth (adelay ~40 ms, −~5 dB) + small leather handle (adelay ~90 ms); soft-limit; trim ~0.49 s; mono 44.1 kHz s16; peak −5 dBFS; fades |

---

## settler_arrive_soldier.wav

| Field | Value |
| --- | --- |
| Character | Short military boot + steel acknowledgment (soldier/guard spawn) |
| Duration | ≈ 0.68 s |
| Source packs | Fantasy Sound Effects (Tinysized SFX); RPG Sound Pack |
| Original files | `boots-leather-step-01.wav` + `battle/sword-unsheathe2.wav` + `inventory/chainmail2.wav` (quiet bed) |
| License | CC0 |
| Authors | **Vehicle** (Jan Schupke / tinysized); **artisticdude** (RPG Sound Pack) |
| Source URLs | https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx ; https://opengameart.org/content/rpg-sound-pack |
| Processing | Boot step + sword unsheathe (adelay ~30 ms) + quiet chainmail rattle (trim 0.35 s, low level); soft-limit; mono 44.1 kHz s16; peak −4 dBFS; fades |
| Note | No CC0 human “huh/grunt” voice pack was available on disk; boot+steel fulfills the allowed alternate |

---

## settler_arrive_generic.wav

| Field | Value |
| --- | --- |
| Character | Fallback arrival for other settler roles (soft step + belt leather + quiet UI confirm) |
| Duration | ≈ 0.60 s |
| Source packs | Kenney RPG Audio; Kenney Interface Sounds |
| Original files | `footstep01.ogg` + `beltHandle1.ogg` + `confirmation_002.ogg` |
| License | CC0 |
| Author | **Kenney** (www.kenney.nl) |
| Source URLs | https://kenney.nl/assets/rpg-audio ; https://kenney.nl/assets/interface-sounds |
| Processing | Footstep + belt handle (adelay ~35 ms) + quiet confirmation (adelay ~60 ms, low level); soft-limit; mono 44.1 kHz s16; peak −5 dBFS; fades |

---

## barracks_ready.wav (optional)

| Field | Value |
| --- | --- |
| Character | Distinct barracks/military-ready cue (steel draw + short steel jingle + confirm) |
| Duration | ≈ 0.59 s |
| Source packs | RPG Sound Pack; Kenney Music Jingles; Kenney Interface Sounds |
| Original files | `battle/sword-unsheathe.wav` + `Audio/Steel jingles/jingles_STEEL00.ogg` (trim 0.55 s) + `confirmation_001.ogg` |
| License | CC0 |
| Authors | **artisticdude**; **Kenney** |
| Source URLs | https://opengameart.org/content/rpg-sound-pack ; https://kenney.nl/assets/music-jingles ; https://kenney.nl/assets/interface-sounds |
| Processing | Unsheathe + short steel jingle (adelay ~40 ms) + quiet confirmation; soft-limit; mono 44.1 kHz s16; peak −4 dBFS; fades |

---

## Gaps / honesty

- **No CC0 human voice “huh/ready” grunt** was found in local packs or downloadable without a non-CC0 license (OGA “Soldier Voice Acting” is **CC-BY 3.0** — skipped). Soldier/barracks cues use **real boot+steel / sword foley** instead, which the brief explicitly allows.
- **farm_ambient** is a short excerpted flock bed (sheep + bells), not a seamless infinite loop. Suitable as a one-shot ambient sting / complete cue ≤3 s.
- Freesound **Breviceps** Loud Sheep Bah is CC0 but requires login for the full WAV; HQ preview was cached for audition only and **not** used in the final pack (OGA + BigSoundBank used instead).
- Wikimedia Commons `Sheep_bleat.ogg` (CC0, Eviatar Bach) was downloaded but too quiet/short for the main cue; unused in finals.
- OGA “Farm animals” pack is **CC-BY-SA 3.0** — skipped.

## Local packs consulted (already under `/workspace/sns-audio/packs/`)

Kenney RPG / Interface / Jingles / Impact; rubberduck wood-metal; Tinysized Fantasy SFX; RPG Sound Pack (artisticdude); steps (qubodup); GUI Lokif; Clickety; Monster Vol.2 — plus newly downloaded Sheep Baa + BigSoundBank sheep/flock under `packs/sheep/`.
