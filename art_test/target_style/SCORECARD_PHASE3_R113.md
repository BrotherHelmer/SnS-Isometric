# Phase 3 — R113 Scorecard (round188) — internal only

## MY CHOICE (stated as required): the green dominance (vegetation colour family)
Named by Black at R109/R107; a colour-family surface, not layout. **All layout positions R110–R112 kept exactly; no wholesale re-layout started (that is Helmer's decision, per Black).**

## Changes (colour only; sun/shadow rig R108–R109 untouched — no tint root lives there)
- Terrain shader grass tint at root: ×vec3(1.04,0.99,0.83)×0.87 → **×vec3(1.13,0.93,0.76)×0.85** (red up, green/blue down = warm olive). Uniform multiplier: R96–R97 meadow drifts and the R97 centre lift are relative and survive (verified in full frame — centre still varied).
- Leaf palette deepened/warmed: 47852e→**407828**, 68a83f→**5e9638**; canopy material albedo (1.04,0.99,0.90)→**(1.03,0.96,0.85)**.
- `foliage_painted.png` warm-shifted at the texture root (R×1.07, G×0.95, B×0.90; mean (102,143,70)→(~110,136,63)) — canopy colour is texture×vertex×albedo, so the texture is a genuine family root.
- Outer ground plane tint warmed slightly (0.38,0.42,0.27)→(0.40,0.42,0.25).
- Trees: colour only — no recount, no resizing, no geometry change (R98/R99/R107 form and cluster gains kept).

## Measured
- Frame G−R: R112 **+15.1** → R113 **+9.1** (target +3.0). Means: (125.3, 134.4, 59.5) vs target (115.3, 118.4, 71.2). Green dominance reduced, not eliminated.
- **283 draws**, prims 458,132, authored tris ~165,974 — all identical to R112 (colour-only change confirmed).

## Judgement
- Full frame: grass reads warm olive-rich rather than bright yellow-green, especially in foreground and shaded areas; sunlit meadow still lively, not muddy/brown. Paths and worked earth remain readable against the deeper grass.
- Trees close: canopies deeper olive with shade masses staying deep; sunlit tops still bright — no near-black return. Honest (colour only, per brief): lump *form* is unchanged this round; only its colour family moved.
- All other surfaces, the sun rig, and every layout position unchanged.

## Verdict
**R113: honest self-assessment — green dominance measurably reduced toward the target's olive; borderline overall.** Awaiting Black. Nothing to Helmer (wholesale re-layout decision is his, via Black).
