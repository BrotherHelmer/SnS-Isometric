# Phase3 R8 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: round28.png, round28_close.png, round29.png, round29_close.png (UVx3 test), sheet SCORECARD_PHASE3_R8.png
Perf R29: 140 draws, 75,425 prims, ~22,182 authored tris; buildings <1500.

Roof shingles: PARTIAL — custom triangular-prism ArrayMesh built (slopes explicit UV u=ridge x2, v=eave->ridge; plaster gables; eave shadow). Castle cones with roof_painted wrap READ as shingle courses in close shot (round28_close, tower top-left). House prism faces still smooth red in close shot; UV v-density x3 changed nothing, so prism UV sampling is not taking effect (unresolved: SurfaceTool->append_from UV path suspected; cones via CylinderMesh UV work). Old geometry shingle strips now float above prism — remove next. Headline NOT verified for houses.
Snow: FIXED-ish — neutral grayscale detail_noise on terrain replaced painted grass multiply, snow now clean white-blue, large, in frame top-right. Hill below snow still tan ramp.
Trees: IMPROVED — lighter canopy variants, elongated pines; core still dark facets.
Light/vignette/pools: IMPROVED — Pillow vignette overlay on CanvasLayer (visible corners), 3 warm Omni pools + centre pool, cool fill; still no real warm-pool falloff reading at this scale.
Activity: IMPROVED — 6 figures, 4 KayKit skins (Farmer_B/A, Rogue_Hooded, Rogue — red hair, green hood visible), all Walking_A; no static work poses yet, logs identical.

VERDICT: NOT MATCHES. Prism roof is built but house shingle reading remains the open technical blocker; snow/vignette/activity are genuine fixes.
