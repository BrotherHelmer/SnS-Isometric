# Phase 3 R135 — re-rank, then fix the largest fixable (dirt, round 2)

Draws 283 (cap 290) | Prims 543,291 (~550k ceiling) | Authored tris unchanged — texture/material only. Stone and canopy closed (guard-measured only).

## Ranked table (round210 vs target, classify_r130.py)
| class | dRGB | dShare | HSV gaps (ours vs target) | disposition |
|---|---|---|---|---|
| sky/background | .333 | −1.84pp | sat artefact | excluded (n=200, flags/figures) |
| **dirt/worn** | **.098** | +12.17pp | sat +.169, val −.066 | **largest fixable — fixed this round** |
| stone | .097 | −10.00pp | sat +.086, val +.122 | CLOSED: small-n pool (n=521); root texture median still (142,137,129) sat .092/val .557 vs target .079/.545 — ranking does not justify reopening, not retuned |
| roofs | .081 | −3.54pp | sat +.193 | next candidate, with caveat below |
| snow/sky_pale | .078 | −0.93pp | val +.094, sat +.149 | candidate after roofs |
| rock/hill | .071 | −0.98pp | sat −.096, val +.066 | R132 diminishing-returns accepted |
| grass | .035 | +0.39pp | — | guard |
| canopy/trees | .021 | +4.74pp | — | closed, guard |

## Fix (dirt family, same scope as R134: paths/yards/links/aprons/terraces on dirt keys; timber wood excluded)
R134's mean-grey desaturation had cost dirt value (class val .631→.573). Round 2: `dirt_painted.png` redone from the pre-R134 original — value-preserving desaturation ×0.40 (toward per-pixel max) + lift ×1.05; palette tones value-preserving desat ×0.15 + lift ×1.10 (e.g. path centres ccba98→e0cfaf). No geometry/placement/light changes.

## After (round211, same method)
- Whole dirt class: sat .623 → .634 (flat — brightening re-saturates slightly through the frame stack), val .573 → .600 (target .639), dRGB .098 → .085.
- Light-ground subset (path/yard centres): sat .518 → **.476** (target .438; gap .080 → .038; cumulative over R134+R135: .105 → .038, 64% closed), val .722 held (target .710).
- Dark bucket (timber/hill pixels in the classifier bucket, out of scope): sat .667 — the reason the whole-class median cannot reach target within ground scope.
- Close view: pale warm centres, R118 fringe still graduates, R117 ruts read. One step lighter would wash the paths out — stopped here deliberately.
- Guards: canopy median identical (58,86,16), dRGB .021 → .020 (closed, not retuned); roofs identical (150,77,46), .081; grass .035 → .037; stone classifier .097 → .135 and rock .071 → .086 are pool spill only — neither was touched in this diff.

## Next candidate (named)
Roofs, by generic ranking (dRGB .081, sat +.193) — but only after re-measuring with R122's roof-specific lit/shade method, which previously contradicted the generic bucket. No roof retune on the generic number alone. Following that: snow/sky_pale (.067, value +.094).

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. The dirt ground family is now measurably in target's muted earth (light-ground saturation gap .038, value matched) and first glance follows: paths read pale warm, neither orange nor grey mud. The whole-class median remains bound by out-of-scope wood/hill pixels. Form and composition remain the standing limit, as Black noted. Nothing shown to Helmer.
