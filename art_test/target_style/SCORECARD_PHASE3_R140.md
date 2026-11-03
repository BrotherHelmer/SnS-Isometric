# SCORECARD PHASE3 R140 (round216) — FORM via SURFACE PAINTING (internal, Black to judge)

Base: R139 83da485 (round215). Method: TEXTURES ONLY. Zero .gd changes (git diff audit:
only 6 PNGs under art_test/target_style/textures_painted modified; .import/project.godot
noise left unstaged; .uid untouched). No shader/light/layout/geometry change.
Sun/shadow rig R108/R109 untouched.

## What was painted
Mean-preserved multiplier painting (soft elliptical light/shadow clumps -> gaussian blur
-> mid-frequency blotch field -> per-channel mean normalized to exactly 1.0 -> clip),
authored at screen scale: crowns sit at 20-40px, so clumps are 45-190px in texture
(several px on screen), no fine dot noise.
- foliage_painted: KEPT v3 (very large soft clumps only). v2 (smaller cluster dabs)
  read speckly in A/B crops -> dropped dabs, kept v3.
- plaster / stone / roof / wood / thatch: KEPT (soft tonal clumps, brushy variation,
  painted highlight/shadow pockets; existing voronoi/tile structure preserved underneath).
- NOT painted: dirt (closed), grass/meadow, rock, grain_painted (global base for mat_col,
  side-effect risk), detail_noise, foliage_card.
Texture medians (before->after): foliage (114,127,87)->(114,126,87);
plaster (228,209,174)->(229,210,174); stone (145,140,132)->(142,136,129) [OPENLY: stone
TEXTURE median shifted -3/-4/-3, but classifier root median unchanged, see guards];
roof (155,105,80)->(154,105,79); wood (124,90,54)->(120,86,53) [not a closed class];
thatch (184,145,67)->(182,143,67). Texture means essentially identical by construction.

## Perf / frozen proof
- draws 288 (<=288 cap), prims 541,405 — IDENTICAL to round215. Texture-only claim verified.
- Layout AND geometry byte-frozen: no code diff at all this round.

## Guards (classify_r130, round215 -> round216) — ALL IDENTICAL
- canopy/trees (56,94,19) -> (56,94,19), dRGB .029, share 15.61% both
- stone (180,183,152) -> (180,183,152), share 1.55% both
- dirt (146,115,56) -> (146,115,56), share 30.16% both
- roofs (148,75,45) -> (148,75,45), share 8.88% both
No closed-class median shifted in frame. The only median shift anywhere is the stone
source-texture median above, which does not propagate to the frame median.

## Self-judgement at native 1280x720 + crops: FAIL ~6.8/10 (was 6.5)
A/B crops (215 left / 216 right): stone walls gain subtle grey mottling, thatch and roof
masses read deeper/denser, crowns gain soft tonal clumping without speckle (v3).
BUT at full frame the masses still read as the same low-poly models wearing busier
textures — the faceted crown geometry and flat building volumes dominate first glance;
painted clumps are low-contrast after lighting+mip and do not yet read as hand-painted
masses. Painting helped surface richness, it did not change form language.
Kept: all 6 repaints (guards clean, no speckle in v3, no perf cost).
Dropped: foliage v2 small-dab layer (speckle, mip lesson confirmed again).
Honest read for Black: incremental surface win, not a PASS.
