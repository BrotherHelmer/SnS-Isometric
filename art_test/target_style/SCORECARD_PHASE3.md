# Phase3 scorecard vs target — for Black PASS/FAIL, NOT Helmer
Screenshots: phase2/round6.png, round7.png, round8.png (final), SCORECARD_PHASE3.png (side-by-side)
Perf R8: 62 draw calls, 26,258 prims, ~5,824 authored tris vignette; buildings <1500 tri each (est. castle ~900, house ~450 with shingles, hut ~350). Textures all 1024 CC0 in-repo (meadow/dirt/stone/plaster/timber/slate).

Per Black's 5 deviations:
1. Terrain grain: IMPROVED NOT PASS — meadow texture grain now visible, square patches removed, hill+snow added; but ground reads muddy dark-olive/brown, not lush painterly green; path is dark wood-like strip, height variation only hill blob.
2. Building detail: IMPROVED NOT PASS — stone texture+courses on castle, slate-tinted roof + shingle rows, thatch rings, plaster/timber; but house side walls render near-black (plaster UV/shading bug to fix), castle keep plain, windows sparse.
3. Shadows/light: NOT PASS — shadow_opacity 0.38 + contact-AO discs added, warm sun; still hard-edged, flat depth vs target soft warm.
4. Scale/density: IMPROVED NOT PASS — camera 19, 3 houses+2 huts+castle, flags/barrels/crates/fence/props, carriers; still sparse vs target dense village, buildings large.
5. Trees/carrier: IMPROVED NOT PASS — carrier now real KayKit Farmer_B (straw hat, blue) with scene-level log (R6 giant-log bug fixed); no walk cycle found in GLB (no AnimationPlayer), static. Trees still smooth two-tone lollipops, no faceted painterly canopy texture.

Overall verdict (mine): NOT MATCHES — at first glance clearly distinguishable from target. Recommend Black FAIL, next fixes in order: house wall material bug, lush grass tint/texture blend, canopy facet+texture, animation library attach for carrier, denser layout.
