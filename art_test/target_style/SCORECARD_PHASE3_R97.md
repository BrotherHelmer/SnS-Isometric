# SCORECARD — Phase 3 R97 (round172): mid-frame meadow (internal only)

Reference: restored target, R96 round171. Full frame + centre close.

## Diagnosis (three stacked roots, all fixed)
1. The R75/R76 worked patches **explicitly skip the centre**
   (`if Vector2(px2,pz2).length() < 6.0: continue`), so grounded variation
   existed everywhere except mid-frame.
2. The centre sits in a broad dark lobe of the low-frequency vertex shade
   (`gsf` down to ~0.80 around the settlement) and inside one lobe of the
   single existing patch function (~20u period).
3. Meadow texture variation is multiplicative (`v_c * md`), so on the dark
   centre vertex colours its absolute contrast compresses away.

## Fixes — centre grass 6.5/10
- Vertex colour (flat terrain only, slope<=0.30): a medium-scale patch term
  (0.83/0.71/diagonal sines) lerping toward lighter meadow 69a83a and worn
  b8a05e at its peaks, plus a gentle centre lift (up to +9% via lightened
  lerp within 13u) compensating the dark lobe. Dirt/rock/snow terms after it
  are unchanged, and slope/haze behaviour is untouched.
- Terrain shader: meadow texture contrast expanded around its pivot
  ((md-0.80)*1.5+0.80, clamped 0.50-1.30) so texture variation survives on
  dark vertex colours; edges get the same expansion proportionally and were
  checked not to blow out or regress.
- Grounded centre detail in R76 language: 7 `_ground_patch` worn/meadow
  patches (1.6-2.2u) on open centre grass, positions chosen to avoid
  buildings and path lines, using the existing outer-patch colour keys.
**Does mid-frame grass now vary like the edges? Mostly yes** — full frame
shows lighter meadow and worn areas threaded through the settlement at the
same scale as the field variation, paths with stone edging still read
clearly, and worked patches do not double-read (centre patches are the same
system, not a second language). Honest remainder: variation is still gentler
than the target's lush, dense meadow — the centre reads varied green, not yet
rich meadow — and a few centre patches sit close to path edges (seated and
flat, they read as worn verges rather than obstacles).

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R97 round172: **275 draws / 318,712 prims / ~147,062 authored tris** — draws
unchanged (vertex/shader change + patches on existing colour keys).

Renders: evidence `phase3/round172.png` + `phase3/round172_close.png` (1280x800).
