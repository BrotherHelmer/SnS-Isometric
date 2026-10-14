# Beta overnight (beta/overnight) progress
Base: hotfix/demo2-fog-overlay 6a2891a (b4dab21 + Low shadows off/2 splits). Evidence: /home/box/cos/evidence/2026-10-15-sns-beta/
Gate: 20-min playthrough no crash, >=45 FPS avg Shard 1920x1200@125% fullscreen, full build menu, UI tabs readable, ChatGPT >=8/10 (via Black).
Baseline: hotfix7 run7 (b4dab21, Low) 37.5 avg FPS, median 26.5 ms, GPU median 15.3 ms -> GPU is NOT the 26 ms; Shard display is 60 Hz with FIFO vsync (frames just over 16.7 ms wait for the next vblank).

- 23:45 branch beta/overnight off 6a2891a. Cherry-picked from vr/greybox: harness-only quarry backoff + iso flags (5b8f4f7, minus greybox shot code). MSAA/SSAO/glow/SSR already off in Low (Shard auto-picks Low on iGPU), nothing else to pull.
- 23:50 R1 change: VSync mailbox by default (fallback FIFO), --vsync=fifo|off override.
