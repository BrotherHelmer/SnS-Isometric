# Perf checkpoint matrix (MEASUREMENT ONLY - prepared in hotfix 7, not run).
# Compares on Shard Low, seed 424242, 300 s each, cold shader cache per run:
#   base | fps cap 30 | 3D scale 0.88 & 0.85 (UI stays native) | cheap ground | cheap foliage | all cheap
# Flags only exist in the gate harness; shipped defaults are untouched.
param([string]$Root="C:\Users\doche\snsgate_run",[string]$Exe="$Root\x\ShardAndSovereign-Demo2-hotfix4-affe17e\ShardAndSovereign.exe",[int]$Seconds=300)
$log="$Root\checkpoint_runner.log"
function L($m){ "$(Get-Date -Format HH:mm:ss) $m" | Add-Content $log }
$runs=@(
 @("cp_base",@()),
 @("cp_fps30",@("--gate-fps-cap=30")),
 @("cp_scale88",@("--gate-render-scale=0.88")),
 @("cp_scale85",@("--gate-render-scale=0.85")),
 @("cp_cheapground",@("--gate-diag-cheap-ground")),
 @("cp_cheapfoliage",@("--gate-diag-cheap-foliage")),
 @("cp_allcheap",@("--gate-diag-cheap-ground","--gate-diag-cheap-foliage"))
)
if (Get-Process | ? { $_.ProcessName -match 'Shard|Sovereign' }) { L "game running - abort"; exit 1 }
foreach($r in $runs){ $n=$r[0]; $out="$Root\$n"; New-Item -ItemType Directory -Force $out,"$Root\appdata_$n" | Out-Null
 $env:APPDATA="$Root\appdata_$n"; L "$n start"
 $a=@("--fullscreen","--","--gate-autoplay=$($out.Replace('\','/'))","--fps-overlay","--gate-seconds=$Seconds","--gate-seed=424242")+$r[1]
 $p=Start-Process $Exe -ArgumentList $a -PassThru -RedirectStandardOutput "$out\stdout.txt" -RedirectStandardError "$out\stderr.txt"
 if (-not $p.WaitForExit(($Seconds+180)*1000)) { L "$n timeout kill"; $p | Stop-Process -Force }; L "$n done"; Start-Sleep 5 }
L "ALL DONE"
