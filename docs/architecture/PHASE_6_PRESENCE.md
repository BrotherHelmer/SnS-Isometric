# Phase 6 — Presence: performance, score, minimap

The One Shard loop is already in. This pass makes it playable and readable at province scale.

## Player-facing

- **Lag:** Grass no longer rebuilds whenever a tree is chopped. Tufts sit on a separate layer, only on revealed ground, denser in the yard.
- **Score:** Day mix uses a cheerier plucked pastoral stem plus settlement activity. Night drops the village colour for drones, low percussion, and synthesised distant screams during raids. Original project-owned render from `tools/generate_presentation_audio.py` — not a licensed Settlers recording.
- **Minimap:** Lower-right province map. Fog, your roads/buildings, rival roads, Wyrd sites, cargo carriers, hostiles, the Shard, and a camera frame. Click to pan.

## Still the bet

Roads and Outposts remain the hunger that lights the dark and worsens the night. The minimap is how you see the Shard you want and the rival coming. Temptation versus safety is still Wyrd extraction versus Lumen.

## Tests

- `tests/phase6_presence.gd`
- `tests/phase4_2_audio_evidence.gd` (day/dusk/night/raid stems now expected)
- `tests/phase4_2_parse_smoke.gd`
- `tests/phase5_settlement_speak.gd`
