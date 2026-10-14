# Beta overnight (beta/overnight) progress
Base: hotfix/demo2-fog-overlay 6a2891a (b4dab21 + Low shadows off/2 splits). Evidence: /home/box/cos/evidence/2026-10-15-sns-beta/
Gate: 20-min playthrough no crash, >=45 FPS avg Shard 1920x1200@125% fullscreen, full build menu, UI tabs readable, ChatGPT >=8/10 (via Black).
Baseline: hotfix7 run7 (b4dab21, Low) 37.5 avg FPS, median 26.5 ms, GPU median 15.3 ms -> GPU is NOT the 26 ms; Shard display is 60 Hz with FIFO vsync (frames just over 16.7 ms wait for the next vblank).

- 23:45 branch beta/overnight off 6a2891a. Cherry-picked from vr/greybox: harness-only quarry backoff + iso flags (5b8f4f7, minus greybox shot code). MSAA/SSAO/glow/SSR already off in Low (Shard auto-picks Low on iGPU), nothing else to pull.
- 23:50 R1 change: VSync mailbox by default (fallback FIFO), --vsync=fifo|off override.
- 00:04 R1 Shard gate (a249a23, pck eb40c1e3, Low, mailbox active): 20 min, no crash, day 2 reached, avg 42.0 FPS (t>=90; hotfix7 37.5), 1% low 19.8, median 25.1 ms. FAIL (<45). FPS decays with town size: 56-58 FPS 0-4 min -> 27 FPS at 18-20 min (119 buildings); GPU median 13 -> 17.6 ms, frame 16 -> 30 ms -> late-game CPU+GPU.
- 00:08 harness: --gate-loadtest=N (load autosave, measure N s), --gate-diag-hide-ui / -hide-chars. Late-game A/B on Shard from the r1 autosave: base, vsync off, scale 0.70, hide UI, hide chars, base2 (150 s each).
- 00:26 Late-game loadtest (lt_a, 119 bld, 150 s each, t>=50): base 31.0 FPS (GPU 16.6) | vsync off 31.4 | scale 0.70 34.7 (GPU 13.5) | hide UI 28.9 | hide chars 23.7 | base2 23.1. base->base2 drift = every script section ~1.5x slower after 15 min continuous load => Shard CPU thermal/power throttling (AC, Balanced); hideui/hidechars not interpretable. Presentation sync runs on ~1/3 frames at ~18 ms sync + ~10 ms capture -> frame pacing. _sync_map_markers freed + rebuilt every Label3D/mesh on every tick (~7.5 ms per sync).
- 00:29 R2 changes: map markers rebuilt only when the marker list changes; Low 3D render scale 0.85 -> 0.75 (FSR). CI quick PASS (known smoke), pck 0b999b4d.
- 00:29 R2 gate launched on Shard (d84f040). At t=5 min: 57.8 avg (r1 at same point ~55).
- 00:33 R3 change (local, built /tmp/beta_r3): presentation capture and 3D apply alternate frames (never both on one frame; one tick of extra latency ~16 ms). Box xvfb 200 s harness: 0 script errors, settlement grows.
