# VR S1 greybox PROGRESS

- 1e26a63 seeded landform + shader geology + greybox shot harness (WIP). Seed 260918 box shots OK.
- Open: dark band in wide shots, forest density/clearings, shadows check, 4-seed matrix, Shard perf, checkpoint harness port.
- Issue 1 fixed: dark band = ortho near-clip under hills; camera boom lengthens with zoom (shadow distance compensated).
- Issue 2: forest density (+1-2 trunks on interior forest tiles, glade thinning). Crater basalt lightened.
- Cherry-picked hotfix6/7 perf line + gate harness + checkpoint harness (994d203) + Low shadows off/2 splits (6a2891a) onto vr/greybox; export includes production_landform.gd. CI: only known smoke "4 resources still in use"; audit PASS.
- Camera pivot follows ground height (subject was off-centre on raised terrain).
- Issue 4: 4-seed matrix (260918, 261306, 261597, 424242) in /home/box/cos/evidence/2026-10-13-sns-vr-s1/greybox/<seed>/.
- Issue 5/7 BLOCKED: Shard (Spawn) offline at 22:00. Runner ready: tools/perf_checkpoint/greybox_shard.ps1 (Low, Recommended, 6 checkpoint options).
