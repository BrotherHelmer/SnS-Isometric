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
function Run($n,$extra,$mode){
 $out="$Root\iso2\$n"; if (Test-Path "$out\run_done.txt") { return }
 if (Busy) { L "game running - stop before $n"; exit 1 }; New-Item -ItemType Directory -Force $out,"$Root\appdata_iso2_$n" | Out-Null
 $env:APPDATA="$Root\appdata_iso2_$n"; L "$n start"
 if ($mode -eq "gate") { $a=@("--fullscreen","--","--gate-autoplay=$($out.Replace('\','/'))","--gate-seconds=$Seconds","--gate-seed=$Seed")+$common+$extra; $lim=$Seconds+180 }
 else { $a=@("--fullscreen","--","--greybox-shots=$($out.Replace('\','/'))","--greybox-shots-quick","--gfx-seed=$Seed")+$common+$extra; $lim=240 }
 $p=Start-Process $Exe -ArgumentList $a -PassThru -RedirectStandardOutput "$out\stdout.txt" -RedirectStandardError "$out\stderr.txt"
 if (-not $p.WaitForExit($lim*1000)) { L "$n timeout kill"; $p | Stop-Process -Force }; L "$n done"; "done" | Set-Content "$out\run_done.txt"; Start-Sleep 5 }
L "plan: $(($runs | % { $_[0] }) -join ', ')"
foreach($r in $runs){ if ($r[0] -eq "ssao_warmup") { $keep=$Seconds; $Seconds=300; Run $r[0] $r[1] "gate"; $Seconds=$keep } else { Run $r[0] $r[1] "gate" } }
L "ALL DONE"
