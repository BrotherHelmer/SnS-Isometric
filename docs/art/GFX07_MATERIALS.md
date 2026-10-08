# GFX-07: building material pass

Imported settlement meshes keep their silhouettes. This PR only changes
how they catch light.

- Roughness bands: plaster **0.80**, timber **0.70**, roof **0.72**,
  stone **0.85**, metal **0.34**
- Per-building ±5–8% albedo shift from the entity id
- Cheap fresnel `next_pass` stands in for 1–2% mesh bevels

Stacked on GFX-06. No HUD, audio, gameplay or workflow changes.
