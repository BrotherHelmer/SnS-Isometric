# GFX-05: sun / PSSM 2-split

One shadow-casting `DirectionalLight3D` as the form-defining key. Cool fill
stays shadowless.

- PSSM **2-split** (not 4), `directional_shadow_split_1` 0.38
- `directional_shadow_max_distance` **48 m** — just past the strategy camera
- `shadow_bias` 0.03 / `shadow_normal_bias` 0.8
- `light_angular_distance` **0** (no PCSS softness on Medium)

Stacked on GFX-04. No HUD, audio, gameplay or workflow changes.
