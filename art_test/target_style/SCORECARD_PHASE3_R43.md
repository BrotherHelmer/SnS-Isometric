# Scorecard Phase 3 R43 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Form-first houses — honest result
Implemented as directed: wall volume is generated FIRST with
large deformation (lean x/z to 0.55/0.30 amplitude sheared by
height², 19% top taper, uneven top corners ±0.17, mid bulge),
facades (door/windows/timber/shutters) then sit on the front
plane (lean shears in x, so windows stay on the face; verified
no detached facades in close shots), and the roof instance
carries a small tilt following the lean. vi1 tapered walls got
a shear lean as well. Deformation was then exaggerated in
round99 (lean 0.30->0.55, taper 0.15->0.19, top offsets x1.5).

Result at FULL frame: the remaining parametric houses STILL
read as boxes. Diagnosis, third time confirmed at increasing
amplitudes: the house read is dominated by the rectilinear
roof prism + facade grid, not the wall volume. Wall deformation
under a straight prism roof does not change the silhouette
enough at 25-unit frame scale. The deformations that DID change
the read in this phase were whole-form replacements (round,
octagonal, A-frame builders, R38–R40). If form language is to
move further, roofs must deform with walls (sagged/uneven
prism geometry per house, not tilted instances) or the
remaining cottages convert to non-box builders like the rest.

Rounds: 98 (form-first deformation + roof tilt), 99
(exaggerated amplitudes — same read).
Perf round99: 285 draw calls (unchanged), 384,991 prims,
~123,724 authored tris. No facades detached, no draws added.
Retained: 7/12 non-box buildings, crowd, hill, summit, grade.
No animals invented.

Screenshots: phase3/round99.png, round99_close.png,
phase3/round98.png; scorecard SCORECARD_PHASE3_R43.png.
