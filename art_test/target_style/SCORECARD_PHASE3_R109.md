# Phase 3 — R109 Scorecard (round184) — internal only

## Task: richer, darker exposure without losing the R108 shadow gain
Means as sanity guide only (judged by eye vs target): R108 sun frame ~153–156, target ~115, flat R107 baseline ~101. Aim was rich sunny, not flat dark.

## Changes (light/env roots only; sun, casters and all geometry unchanged)
- `tonemap_exposure` 1.00→**0.84** (ACES kept).
- Ambient amb×0.30→**×0.25**, pools 0.15/0.12→**0.12/0.10**, sun 0.20→**0.18** (warm colour and shadow opacity 0.70 untouched — shadows stay sun-driven, ambient was not lifted, so shadow darkness is preserved by construction).
- Saturation 1.12→**1.15**, contrast 1.10 kept.
- Grass at the terrain-shader root deepened to richer olive: tint ×vec3(1.04,0.99,0.83)×**0.87** (was ×1.02 in R107 line). This is a uniform multiplier — R96/R97 meadow variation and the R97 centre lift are relative and preserved (centre checked in full frame: still varied, not dark).

## Measured result
- Frame mean: R108 (155.7, 169.9, 85.2) → R109 **(123.4, 139.3, 61.5)**, target (115.3, 118.4, 71.2). Red/blue now close to target; green remains higher (green-dominant scene content).
- **283 draws** (unchanged), prims 459,528 (unchanged), casters unchanged (canopy/roofs/cliffs), zero geometry/texture changes.

## Breakage check (vs validated readings)
Roofs muted terracotta ✓; castle warm rubble first ✓; cones hand-tiled ✓; paths readable ✓; trees bright tops with deep shade masses, not near-black ✓; mountain composition + snow patches intact ✓; settlement centre meadow varied and not re-darkened ✓; crisp — no fog/vignette added, fog settings untouched ✓.

## Judgement
Full frame now reads rich sunny rather than pale: exposure sits between the flat R107 and pale R108, cast shadows still ground trees/roofs, directional modelling intact (see R109_before_after.png and R109_side_by_side.png). Honest limit: green channel still runs hotter than the target (lush grass area dominates) — the image is richer, not yet the target's exact olive richness.

## Verdict
**R109: honest self-assessment — the R108 reservation (pale exposure) is substantially addressed with the shadow gain kept; borderline overall.** Awaiting Black. Nothing to Helmer.
