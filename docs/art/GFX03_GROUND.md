# GFX-03: ground breakup

One terrain spatial shader. World-space macro noise at **8–20 m** (±5–8%
colour) plus a **0.8–2 m** albedo/normal detail layer, and a dirt/grass
blend toward dry earth `#806347`. Authored grass (`#78815A` / `#586746`)
owns the albedo so the two-scale layer reads from the strategy camera.
Period dusk tint is unchanged. Triplanar stays off on the playable flats.

Stacked on GFX-02. No HUD, audio, gameplay or workflow changes.
