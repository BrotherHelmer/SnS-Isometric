# VR S1 greybox perf ROUND 2 on Shard (measurement only). gb2_* dirs — do not overwrite gbl_*.
# recommended = Medium+shadows native 1.0; scalable_low + --gate-render-scale=1.0 = native Low ref.
# Aborts if the game is already running before a run.
param([string]$Root="C:\Users\doche\snsgate_run",[int]$Seconds=300,[string]$Seed="260918")
$src="$Root\x\ShardAndSovereign-Demo2-hotfix4-affe17e\ShardAndSovereign.exe"; $dir="$Root\x\greybox"; $Exe="$dir\ShardAndSovereign.exe"
if (-not (Test-Path $Exe)) { Copy-Item $src $Exe }
$log="$Root\greybox_r2_runner.log"
function L($m){ "$(Get-Date -Format HH:mm:ss) $m" | Add-Content $log }
$runs=@(
 @("gb2_med",@("--quality=recommended")),
 @("gb2_low_n",@("--quality=scalable_low","--gate-render-scale=1.0")),
 @("gb2_fps30",@("--quality=recommended","--gate-fps-cap=30")),
 @("gb2_scale85",@("--quality=recommended","--gate-render-scale=0.85")),
 @("gb2_scale88",@("--quality=recommended","--gate-render-scale=0.88")),
 @("gb2_cheapground",@("--quality=recommended","--gate-diag-cheap-ground")),
 @("gb2_cheapfoliage",@("--quality=recommended","--gate-diag-cheap-foliage")),
 @("gb2_cheapshadow",@("--quality=recommended","--gate-diag-no-shadow"))
)
foreach($r in $runs){ $n=$r[0]
 if (Get-Process | ? { $_.ProcessName -match 'Shard|Sovereign' }) { L "game running - stop before $n"; exit 1 }
 $out="$Root\$n"; New-Item -ItemType Directory -Force $out,"$Root\appdata_$n" | Out-Null
 $env:APPDATA="$Root\appdata_$n"; L "$n start"
 $a=@("--fullscreen","--","--gate-autoplay=$($out.Replace('\','/'))","--fps-overlay","--gate-seconds=$Seconds","--gate-seed=$Seed")+$r[1]
 $p=Start-Process $Exe -ArgumentList $a -PassThru -RedirectStandardOutput "$out\stdout.txt" -RedirectStandardError "$out\stderr.txt"
 if (-not $p.WaitForExit(($Seconds+180)*1000)) { L "$n timeout kill"; $p | Stop-Process -Force }; L "$n done"; Start-Sleep 5 }
L "ALL DONE"
