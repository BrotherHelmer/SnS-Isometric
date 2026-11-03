# Phase 3 R130 — measurement-led largest deviation

Draws 283 (cap 290) | Prims 543,291 (ceiling ~550k) — texture/material only, authored tris unchanged (244,082).

## Method (checkable)
Both frames resized to 640×400, sampled every 2 px (64,000 pts), one shared HSV classifier (script `classify_r130.py` in phase3 evidence, rerunnable): grass / canopy / dirt-worn / roofs / stone / rock-hill / snow-sky-pale / sky-background. Per-class share-of-frame + median RGB/HSV reported for target and ours.

## Deviation table before (round205 vs target), ranked by colour dRGBmean
| class | dRGB | dShare | target HSV | ours HSV |
|---|---|---|---|---|
| sky/background | .333 | -1.84pp | (.606,.056,.773) | (.592,.890,.784) — artifact, n=198 (flags/blue figures), excluded |
| **stone** | **.128** | -10.41pp | (.167,.079,.545) med (139,139,128) | (.196,.156,.702) n=260 only — most stone misclassified as dirt |
| rock/hill | .115 | -1.15pp | (.174,.585,.463) | (.171,.503,.584) |
| canopy/trees | .081 | +10.07pp | (.220,.729,.333) | (.243,.971,.275) dS +.242 |
| dirt/worn | .080 | **+15.93pp (largest share)** | (.113,.454,.639) | (.100,.697,.647) dS +.243 |
| roofs | .076 | -3.77pp | (.068,.500,.596) | (.049,.691,.596) — guarded R122/R123, not touched |
| snow/sky_pale | .071 | -2.90pp | (0,.027,.863) | (.155,.115,.957) |
| grass | .035 | -5.94pp | (.214,.600,.529) | (.252,.645,.596) — smallest |

Largest share deviation (dirt +15.93pp) is composition/misclassification: target's hill and castle occupy different frame shares under its own framing (layout frozen here), and our warm stone pixels were classifying as dirt. Per brief, fixed the largest fixable colour deviation instead: **stone**.

## Root + fix (stone only)
Root: `stone_painted.png` median (167,140,105) sat .371, multiplied by warm tint (1.06,.99,.88)→`a5917a`, rendered ≈(146,112,73) sat ≈.50 vs target stone (139,139,128) sat .079. Fix: texture desaturated toward per-pixel grey cumulatively ×0.79 (two passes, luminance pattern preserved); shader + material tint (1.06,.99,.88)→(1.02,1.00,.97); stone base `a5917a`→`a9a398` at all uses. R90 per-face warm/cool shader kept — sunlit faces still warm, shaded still cool (stone warmth guard is the shader, not the tan base). No lights/env/geometry/layout changes; roofs/grass/leaf untouched.

## After (round206, same classifier)
- Stone texture median (142,137,129) HSV (.103,.092,.557) vs target (.167,.079,.545): saturation/value essentially matched.
- Stone class dRGB .128 → **.039** (−70%); dirt dRGB .080→.068; dirt share +15.93→+15.02pp (stone pixels reclassifying out of dirt).
- Guards: grass median identical (102,152,54), dRGB .035→.035; roofs (152,78,47)→(151,78,47), dRGB .076→.077; canopy dRGB .081→.078; rock/hill .115→.110; snow/sky unchanged. No validated class drifted beyond small tolerance.
- Remaining ranked gaps (next candidates, not touched): canopy sat .958 vs .729; dirt sat .663 vs .454; rock/hill val .576 vs .463.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10 — but measured distance did close on the fixed class and first glance moves with it: castle and foundations read grey stone like target's instead of sandstone-tan; the focal building sits cooler against green/red. Composition shares (stone area −10.2pp, dirt area +15.0pp) remain layout-bound under frozen positions/framing. An initial render briefly showed 287 draws because a comment insertion swallowed the roof assignment on line 360; caught, reverted to the original line with only the stone colour changed, final verified 283 draws / roofs unmoved.
