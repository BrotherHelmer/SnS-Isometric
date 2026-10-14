# VR S1 greybox PROGRESS

- 1e26a63 seeded landform + shader geology + greybox shot harness (WIP). Seed 260918 box shots OK.
- Open: dark band in wide shots, forest density/clearings, shadows check, 4-seed matrix, Shard perf, checkpoint harness port.
- Issue 1 fixed: dark band = ortho near-clip under hills; camera boom lengthens with zoom (shadow distance compensated).
- Issue 2: forest density (+1-2 trunks on interior forest tiles, glade thinning). Crater basalt lightened.
- Cherry-picked hotfix6/7 perf line + gate harness + checkpoint harness (994d203) + Low shadows off/2 splits (6a2891a) onto vr/greybox; export includes production_landform.gd. CI: only known smoke "4 resources still in use"; audit PASS.
- Camera pivot follows ground height (subject was off-centre on raised terrain).
- Issue 4: 4-seed matrix (260918, 261306, 261597, 424242) in /home/box/cos/evidence/2026-10-13-sns-vr-s1/greybox/<seed>/.
- Issue 5/7 BLOCKED: Shard (Spawn) offline at 22:00. Runner ready: tools/perf_checkpoint/greybox_shard.ps1 (Low, Recommended, 6 checkpoint options).
- Matrix regenerated after camera follow (all 4 PASS); INDEX.md written; Windows pck d430c4b exported to evidence. Shard still offline 23:08 -> perf + checkpoint pending.
- 14/10: harness fixes 5b8f4f7 (quarry backoff gate flag, --gate-iso-* flags, shots honour --quality). Isolation pass starting on Shard.
- 11:37 Shard isolation run started (tools/perf_checkpoint/greybox_iso.ps1, pck 5b8f4f7): 7 Medium baselines interleaved with ssao_off, msaa_off, glow_on, ssr_on, splits2, atlas1024; 200 s each, skip 60 s; then quick day/dusk/night shots per variant.
- 12:16 Shard: runner (greybox_iso2.ps1, pid 8144) on iso_v6_atlas1024; b0-b5, v1-v5 done. Shots next.
- 12:28 Isolation pass DONE; evidence /home/box/cos/evidence/2026-10-13-sns-vr-s1/greybox/isolation/INDEX.md. MSAA off -3.8 GPU ms, SSR +7.1 ms, glow/splits2/atlas1024 noise, SSAO inconclusive (b0 outlier).
- 12:29 SSAO re-isolation started on Shard (greybox_iso_ssao.ps1): 300 s warm-up, b/ssao_off/b/ssao_off/b, msaa+ssao off, b.
- 12:59 SSAO re-run DONE: SSAO off ~0 ms when warm; MSAA+SSAO off -5.8 GPU ms. Appended to isolation/INDEX.md + PR comment.
