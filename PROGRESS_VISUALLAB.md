# VisualLab PROGRESS (vr/visuallab, off vr/greybox)

- 13:05 Branch created. Candidate packs downloaded from official sources (0 kr, CC0), logged in /workspace/sns-visual-reset/S1_ASSET_PROVENANCE.md; tools/visuallab/fetch_assets.sh reproduces + verifies SHA-256; assets/visuallab/ gitignored and excluded from export.
- 41 unknown 2D sprites: explicitly excluded in export_presets.cfg (15 were already covered by folder excludes, 26 added by path). No runtime references.
- 13:17 Lab harness: `--visual-lab=<dir> --lab-candidate=A|B|C --gfx-seed=260918 [--quality=..] [--lab-perf-seconds=N]`. Same greybox seed, same 13-building layout (placed in a ring around the hall), same camera/light/settings; day, close_day, dusk, night. Town Hall/CASTLE, Lumen, Wyrd stay ours (not replaced).
- Box shots: /home/box/cos/evidence/2026-10-14-sns-visuallab/box_{A,B,C}/ + visuallab_sheet_box.jpg.
- CI: only the known smoke error; audit PASS. Shipped pck checked: no assets/visuallab, none of the 41 sprites.

## 2026-10-13 status
- Box shots + sheet done (evidence/2026-10-14-sns-visuallab/visuallab_sheet_box.jpg).
- Shard perf staged: exe + visuallab_shard.ps1 copied; lab-only pck copy failed 3x (Spawn unreachable). Next: copy pck to snsgate_run\x\visuallab\, check no game running, launch runner detached.
