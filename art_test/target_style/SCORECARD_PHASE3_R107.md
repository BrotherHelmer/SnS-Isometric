# Phase 3 — R107 Scorecard (round182) — internal only

## MY CHOICE (stated as required): overall colour/light grade
The only remaining item acting on every surface at once, and named directly by Black (flatter, greener than target). Trees/mountain geometry untouched this round.

## Diagnosis of the current light setup (measured, not guessed)
- **The directional "sun" is not in the tree.** In the baseline, `add_child(sun)` sits after a `#` comment on its own line, so the sun (and all real cast shadows) never existed; the effective rig is sky ambient + a cool directional fill (0.20) + two warm omni pools (0.60/0.55). I deliberately did **not** restructure this — enabling the sun would rewrite every validated shadow read; it is flagged here as a candidate root for a future round if Black wants it.
- Flatness roots in the effective rig: omni pools at 0.60/0.55 wash out directional shading; cool fill lifts shade sides blue; sky ambient energy amb×0.55; environment saturation 0.93 / contrast 1.04 (R70 muting); sun colour/energy values are dead code.
- Green cast roots: meadow texture mean (190, 205, 155) pale yellow-green multiplied near 1.0 in the terrain shader; canopy material albedo (1.05, 1.08, 1.0) boosting green; light leaf family (7cb54f). Measured frame balance: ours G−R = +21.5 vs target +3.0.

## Changes (material/light root only — no textures repainted, no geometry, no new draws)
- Omni pools 0.60→0.34 and 0.55→0.30 (less flat wash); cool fill 0.20→0.09 and warmed (dfe9f5); sky ambient amb×0.55→amb×0.40 (deeper shade sides); sun colour/energy values warmed for if/when it is enabled (1,0.90,0.74 / 1.16, shadow 0.62) — currently inert, documented.
- Existing environment grade pipeline tuned (no overlay, no vignette, fog unchanged): saturation 0.93→1.05, contrast 1.04→1.07. ACES tonemap and R69 crisp settings untouched.
- Terrain shader grass tint at root: ×vec3(1.07, 1.00, 0.85) (warm sunny grass; rock/snow branches untouched).
- Canopy material albedo (1.05,1.08,1.0)→(1.04,0.99,0.90); leaf family deepened (4e8f33→47852e, 7cb54f→68a83f); canopy shade sub-masses darkened 0.20→0.32 (trees gain deeper shade masses via colour only, per brief).
- Process note: two internal renders were caught and fixed — a `//` comment inserted into the single-line terrain shader string, and trailing `#` comments swallowing `add_child` calls on multi-statement lines (canopy/pools). Final render verified clean.

## Perf
- **282 draws exactly** (unchanged), prims 375,288 and authored tris ~166,206 — identical to R106, confirming zero geometry change.

## Judgement (side-by-side first glance; see R107_side_by_side.png)
- Frame is warmer and richer: shade sides and tree shade masses read deeper, highlights warmer, blue cast reduced (mean B 77.8→65.8). Roofs stay muted terracotta (no bright-red return), stone/wood/skin families distinct, image crisp (no fog/vignette added).
- Honest limit: grass remains lush bright green over large areas (the target is also green, but warmer-olive in shadow); the G−R frame statistic is unchanged (+21.5) because grass dominates area even as its shading warmed. The grade is a real step, not a full match to the target's sunny richness — and the biggest single lever (enabling the dormant sun with real cast shadows) remains unused by design this round.

## Verdict
**R107: honest self-assessment — colour/light named failure improved at the root, borderline overall.** Awaiting Black. Nothing to Helmer.
