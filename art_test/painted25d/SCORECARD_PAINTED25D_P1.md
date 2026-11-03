# SCORECARD — Painted 2.5D Prototype P1 (bounded, internal only)

Gate: >=7/10 style match on the test scene before any full asset conversion.
**Verdict: FAIL — ~4/10 overall. Do not convert. R68 low-poly scene untouched (baseline panel).**

Setup: separate scene `art_test/painted25d/painted25d.tscn`, painted transparent sprites
(house / castle section / conifer) + one painted terrain texture on a smooth (non-faceted)
ground slope, invisible box collision stand-ins, ONE existing KayKit 3D carrier (Farmer_B,
Walking_A) walking between houses, fixed isometric camera identical to R68
(size 24.5, same position/target), **filters/post OFF** (linear tonemap, no glow/adjustment).

## Per-point honest verdict
- **Silhouettes — 5/10.** New organic shapes (sagging shingled roof, tiered jagged pine,
  twin-tower castle) read instantly and beat low-poly boxes, but fills are flat vector
  clip-art: almost no painted value modelling or brush texture at real screen size.
- **Terrain — 3/10.** Painted grass slope + winding path, and the rock is a painted ground
  region (no plane mountain wall, as required) — but in frame it is a flat neon-green field;
  the rock section sits mostly east of frame and there is no landform/mountain mass at all,
  which is the target's dominant right-third feature.
- **Sitting-in-landscape — 6/10.** Best art point: painted contact shadows, ground-anchored
  bases, sprites sit on the slope without floating or sinking (see close render).
- **Carrier / overlap — 7/10 (technical PASS).** The 3D KayKit carrier walks between the
  painted houses and a foreground pine correctly occludes him (close render); depth order
  comes from real 3D ground position, collision stand-ins are in place. Integration risk
  for the hybrid approach is therefore low.
- **First-glance kind — 3/10.** First glance reads "flat vector mobile-game village on a
  green field", not the target's muted painted storybook landscape with castle + mountain.
  Palette too saturated/bright despite muting; composition sparse vs target density.

## Diagnosis (artwork / terrain / camera — no shader tweaks made)
Cause is **artwork and terrain, not camera or integration**: (1) sprite painting is flat
fills — hitting the target needs real brush-texture density and value modelling per asset;
(2) terrain is a single flat texture — the target needs a painted landform (mountain mass
as a layered painted backdrop/sprite, not a heightfield wall); (3) palette calibration
(texture colours land ~1.5x brighter under sun+ambient). The 2.5D pipeline itself
(anchors, Y-depth, 3D-unit mixing, contact shadows) is proven and cheap.

Suggested next bounded step (only if approved): ONE hero house + ONE painted mountain
backdrop painted at much higher texture density, retest the same gate. No global shaders.

## Perf
P1 full frame: **41 draw calls, 31,384 primitives** (R68 baseline: 288 draws / 482,213 prims).
Sprites: 15 draw calls total for all buildings/trees; rest is ground, far plane, carrier.

Renders: evidence `painted25d/p1_full.png`, `painted25d/p1_close.png` (1280x800).
