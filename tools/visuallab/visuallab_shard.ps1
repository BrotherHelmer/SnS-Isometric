# VisualLab A/B/C perf on Shard: Medium (recommended, shadows) native + Low (scalable_low); lab-only pck.
# Resumable: finished runs leave run_done.txt. Launch detached (Win32_Process Create) so it outlives the shell.
# Seed 260918, fullscreen native 1920x1200, 120 s fixed camera orbit per run, one discarded warm-up first.
param([string]$Root="C:\Users\doche\snsgate_run",[int]$Seconds=120,[string]$Seed="260918")
function L($m){ "$(Get-Date -Format HH:mm:ss) $m" | Add-Content $log }
function Busy(){ [bool](Get-Process | Where-Object { $_.ProcessName -match 'Shard|Sovereign' }) }
$Exe="$Root\x\visuallab\ShardAndSovereign.exe"; $log="$Root\visuallab_runner.log"
$runs=@(); $runs+=,@("vl_warmup",@("--quality=recommended","--lab-candidate=A"))
foreach($q in @("recommended","scalable_low")){ foreach($k in @("A","B","C")){ $runs+=,@("vl_$($q)_$k",@("--quality=$q","--lab-candidate=$k")) } }
function Run($n,$extra,$mode){
 $out="$Root\visuallab\$n"; if (Test-Path "$out\run_done.txt") { return }
 if (Busy) { L "game running - stop before $n"; exit 1 }; New-Item -ItemType Directory -Force $out,"$Root\appdata_vl_$n" | Out-Null
 $env:APPDATA="$Root\appdata_vl_$n"; L "$n start"
 $a=@("--fullscreen","--","--visual-lab=$($out.Replace('\','/'))","--gfx-seed=$Seed","--lab-perf-seconds=$Seconds")+$extra; $lim=$Seconds+240
 $p=Start-Process $Exe -ArgumentList $a -PassThru -RedirectStandardOutput "$out\stdout.txt" -RedirectStandardError "$out\stderr.txt"
 if (-not $p.WaitForExit($lim*1000)) { L "$n timeout kill"; $p | Stop-Process -Force }; L "$n done"; "done" | Set-Content "$out\run_done.txt"; Start-Sleep 5 }
L "plan: $(($runs | % { $_[0] }) -join ', ')"
foreach($r in $runs){ Run $r[0] $r[1] "lab" }
L "ALL DONE"
