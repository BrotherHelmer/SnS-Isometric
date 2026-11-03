# Scorecard Phase 3 R17 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Softness (main track) — lever by lever, honest
- FXAA (Viewport.SCREEN_SPACE_AA_FXAA): KEPT. Edges measurably less
  crisp/aliased at full frame. Small but real. (MSAA/TAA not enabled:
  FXAA chosen as the cheap static-frame softener; TAA exists in Godot
  4.7 viewport settings but was not needed to test the grade levers.)
- ACES tonemap (was LINEAR) + saturation 1.24 under it: KEPT. This is
  the lever that moved the frame most — warmer roll-off on roofs/snow,
  more vivid painterly grass, less harsh highlight clipping.
- Sky hemisphere ambient (ProceduralSkyMaterial warm sky/ground,
  AMBIENT_SOURCE_SKY): KEPT BUT TAMED. At full energy (round49) it
  washed everything pale; at amb*0.55 (round50+) it gives a soft
  sky/ground fill without flattening. Documented: full-strength sky
  ambient is too strong for this scene's saturated palette.
- Glow (softlight blend, bloom 0.04, strength 0.5): KEPT at low level.
  No blowout this time (round R6 blowout was filmic + high energy);
  contribution is subtle highlight softness only.
- Shadow blur 4.5 -> 7.0: KEPT. Shadow edges visibly softer.
- Fine grain texture (grain_painted, 512px near-white speckle) on all
  plain-colour materials via mat_col: KEPT. Breaks flat colour fills
  subtly at close range; minor at full frame.
- Smooth-shaded canopies: TRIED, REVERTED. Smooth normals + sky ambient
  turned canopies into pale cotton-candy blobs (round49); flat facets
  with per-face colour variance read leafier. Godot-side finding:
  canopy softness must come from colour/texture, not normals, here.
- Overall: frame is softer and warmer than R16, edges and shadows less
  crisp. Still NOT painterly like target — building/terrain surfaces
  remain recognisably flat-shaded low-poly under the grade. The grade
  levers are near their useful limit in this test scene; the remaining
  gap is per-surface painted texture detail at larger scale.

## Rock/talus
- Talus stones scaled down (0.55–1.15) with a third dirt colour
  (a08b6d) added: smaller/dirtier, less large/clean. Rock face, snow,
  composition unchanged from R16 and retained.

## Retained
Composition, chunky warm rock, broader snow, bright canopies (flat
facets restored), shingled roofs, density/life. No animals invented.

Rounds: 49 (all levers, canopy wash fail), 50 (reverts/taming),
51 (saturation 1.24 vivid grade — final).
Perf round51: 167 draw calls, 104,117 prims, ~25,822 authored tris.
Screenshot: phase3/round51.png; scorecard SCORECARD_PHASE3_R17.png.
