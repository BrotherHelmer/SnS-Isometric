# VR S1 render-feature isolation on Shard (measurement only, no shipped defaults changed).
# Resumable: finished runs leave run_done.txt. Launch detached (Win32_Process Create) so it outlives the shell.
# Medium (= recommended, shadows on) native 1920x1200, seed 260918, interleaved baselines.
param([string]$Root="C:\Users\doche\snsgate_run",[int]$Seconds=200,[string]$Seed="260918")
$Exe="$Root\x\greybox_iso\ShardAndSovereign.exe"; $log="$Root\greybox_iso2_runner.log"
function L($m){ "$(Get-Date -Format HH:mm:ss) $m" | Add-Content $log }
function Busy(){ [bool](Get-Process | Where-Object { $_.ProcessName -match 'Shard|Sovereign' }) }
$common=@("--quality=recommended","--gate-bot-quarry-backoff")
$runs=@(); $runs+=,@("ssao_warmup",@())
$runs+=,@("ssao_b1",@()); $runs+=,@("ssao_v1_off",@("--gate-iso-ssao=0")); $runs+=,@("ssao_b2",@()); $runs+=,@("ssao_v2_off",@("--gate-iso-ssao=0")); $runs+=,@("ssao_b3",@())
$runs+=,@("ssao_v3_msaa_ssao_off",@("--gate-iso-ssao=0","--gate-iso-msaa=0")); $runs+=,@("ssao_b4",@())
foreach($r in $runs){ if ($r[0] -eq "ssao_warmup") { $keep=$Seconds; $Seconds=300; Run $r[0] $r[1] "gate"; $Seconds=$keep } else { Run $r[0] $r[1] "gate" } }
L "ALL DONE"
