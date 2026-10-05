# GFX-04: grounding / AO

Forward+ SSAO plus cheap contact discs so buildings, trees and props occupy
the terrain instead of floating on it.

- SSAO radius **0.95 m** (0.7–1.2 m band), intensity 1.15, `light_affect` 0.10
  so sunny faces stay clean.
- Half-resolution SSAO is the project default (`environment/ssao/half_size`).
- One contact-AO disc per building. Off-map edge forest and per-prop discs
  stay off so lavapipe overdraw stays inside the dusk/night +15% guard.
  No per-tile `Decal` nodes.

Stacked on GFX-03. No HUD, audio, gameplay or workflow changes.
