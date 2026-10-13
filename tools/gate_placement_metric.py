# Placement metric with harness bot think time removed from each game frame.
# Per build order (DEMO_AI t=game_s): worst (frame_ms - think_ms) over frames within 1.5 game-s after it.
import csv,re,statistics as st,sys,bisect
d=sys.argv[1]
F=list(csv.DictReader(open(d+'/fps.csv')))
tw=[float(r['t_wall']) for r in F]; gs=[float(r['game_s']) for r in F]
def g_of(t):
  i=bisect.bisect_left(tw,t)
  if i<=0: return gs[0]
  if i>=len(tw): return gs[-1]
  a,b=tw[i-1],tw[i]; return gs[i-1]+(gs[i]-gs[i-1])*(t-a)/max(1e-9,b-a)
R=[r for r in csv.DictReader(open(d+'/d5_frames.csv')) if float(r['t_wall'])>=90]
G=[(g_of(float(r['t_wall'])),float(r['frame_ms'])-float(r.get('think_ms') or 0),float(r['frame_ms'])) for r in R]
G.sort(); keys=[x[0] for x in G]
ev=[float(m.group(1)) for l in open(d+'/stdout.txt',errors='ignore') for m in [re.search(r'DEMO_AI t=([\d.]+) (\w+)',l)] if m and m.group(2)!='SCOUT']
w=[];raw=[]
for e in ev:
  i=bisect.bisect_left(keys,e); j=bisect.bisect_right(keys,e+1.5)
  if j>i: w.append(max(x[1] for x in G[i:j])); raw.append(max(x[2] for x in G[i:j]))
w.sort();raw.sort()
p=lambda v:f"median={st.median(v):.0f} p90={v[int(len(v)*.9)]:.0f} max={v[-1]:.0f} <=50ms {sum(x<=50 for x in v)}/{len(v)}"
print(f"{d}: placements={len(w)}\n  game-only (think removed): {p(w)}\n  raw frame:                 {p(raw)}")
# Baseline: same metric in 1.5 s windows starting 4 game-s BEFORE each order (no placement in window)
b=[]
evs=sorted(ev)
for e in ev:
  s=e-4.0
  if any(s<=x<=s+1.5 for x in evs): continue
  i=bisect.bisect_left(keys,s); j=bisect.bisect_right(keys,s+1.5)
  if j>i: b.append(max(x[1] for x in G[i:j]))
b.sort()
if b: print(f"  baseline windows (no order): {p(b)}")
