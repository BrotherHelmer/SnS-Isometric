# VR S1 greybox perf on Shard (measurement only). Requires $Root\x\greybox\ShardAndSovereign.pck
# (box CI export of vr/greybox); the exe is copied from the hotfix4 gate folder. Aborts if the game is running.
# NOTE: the profile id is "scalable_low" (the iGPU default). "--quality=low" is not a profile and silently
# falls back to "recommended" (1st Shard run 13/10 measured recommended for every gb_low/gbcp_* row).
param([string]$Root="C:\Users\doche\snsgate_run",[int]$Seconds=300,[string]$Seed="260918")
$src="$Root\x\ShardAndSovereign-Demo2-hotfix4-affe17e\ShardAndSovereign.exe"; $dir="$Root\x\greybox"; $Exe="$dir\ShardAndSovereign.exe"
if (-not (Test-Path $Exe)) { Copy-Item $src $Exe }
$log="$Root\greybox_runner.log"
function L($m){ "$(Get-Date -Format HH:mm:ss) $m" | Add-Content $log }
$runs=@(
 @("gbl_low",@("--quality=scalable_low")),
 @("gbl_fps30",@("--quality=scalable_low","--gate-fps-cap=30")),
 @("gbl_scale88",@("--quality=scalable_low","--gate-render-scale=0.88")),
 @("gbl_cheapground",@("--quality=scalable_low","--gate-diag-cheap-ground")),
 @("gbl_cheapfoliage",@("--quality=scalable_low","--gate-diag-cheap-foliage")),
 @("gbl_allcheap",@("--quality=scalable_low","--gate-diag-cheap-ground","--gate-diag-cheap-foliage")),
 @("gbl_low_b",@("--quality=scalable_low"))
)
foreach($r in $runs){ $n=$r[0]
 if (Get-Process | ? { $_.ProcessName -match 'Shard|Sovereign' }) { L "game running - stop before $n"; exit 1 }
 $out="$Root\$n"; New-Item -ItemType Directory -Force $out,"$Root\appdata_$n" | Out-Null
 $env:APPDATA="$Root\appdata_$n"; L "$n start"
 $a=@("--fullscreen","--","--gate-autoplay=$($out.Replace('\','/'))","--fps-overlay","--gate-seconds=$Seconds","--gate-seed=$Seed")+$r[1]
 $p=Start-Process $Exe -ArgumentList $a -PassThru -RedirectStandardOutput "$out\stdout.txt" -RedirectStandardError "$out\stderr.txt"
 if (-not $p.WaitForExit(($Seconds+180)*1000)) { L "$n timeout kill"; $p | Stop-Process -Force }; L "$n done"; Start-Sleep 5 }
L "ALL DONE"
