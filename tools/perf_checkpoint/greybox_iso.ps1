# VR S1 render-feature isolation on Shard (measurement only, no shipped defaults changed).
# Medium (= recommended, shadows on) native 1920x1200, seed 260918, interleaved baselines.
param([string]$Root="C:\Users\doche\snsgate_run",[int]$Seconds=200,[string]$Seed="260918")
$Exe="$Root\x\greybox_iso\ShardAndSovereign.exe"; $log="$Root\greybox_iso_runner.log"
function L($m){ "$(Get-Date -Format HH:mm:ss) $m" | Add-Content $log }
function Busy(){ [bool](Get-Process | Where-Object { $_.ProcessName -match 'Shard|Sovereign' }) }
$common=@("--quality=recommended","--gate-bot-quarry-backoff")
$variants=@(,@("ssao_off","--gate-iso-ssao=0")); $variants+=,@("msaa_off","--gate-iso-msaa=0"); $variants+=,@("glow_on","--gate-iso-glow=1"); $variants+=,@("ssr_on","--gate-iso-ssr=1"); $variants+=,@("splits2","--gate-iso-splits=2"); $variants+=,@("atlas1024","--gate-iso-shadow-atlas=1024")
$runs=@(); $runs+=,@("iso_b0",@())
$i=1; foreach($v in $variants){ $runs+=,@("iso_v$i`_$($v[0])",@($v[1])); $runs+=,@("iso_b$i",@()); $i++ }
function Run($n,$extra,$mode){
 if (Busy) { L "game running - stop before $n"; exit 1 }
 $out="$Root\iso\$n"; New-Item -ItemType Directory -Force $out,"$Root\appdata_iso_$n" | Out-Null
 $env:APPDATA="$Root\appdata_iso_$n"; L "$n start"
 if ($mode -eq "gate") { $a=@("--fullscreen","--","--gate-autoplay=$($out.Replace('\','/'))","--gate-seconds=$Seconds","--gate-seed=$Seed")+$common+$extra; $lim=$Seconds+180 }
 else { $a=@("--fullscreen","--","--greybox-shots=$($out.Replace('\','/'))","--greybox-shots-quick","--gfx-seed=$Seed")+$common+$extra; $lim=240 }
 $p=Start-Process $Exe -ArgumentList $a -PassThru -RedirectStandardOutput "$out\stdout.txt" -RedirectStandardError "$out\stderr.txt"
 if (-not $p.WaitForExit($lim*1000)) { L "$n timeout kill"; $p | Stop-Process -Force }; L "$n done"; Start-Sleep 5 }
L "plan: $(($runs | % { $_[0] }) -join ', ')"
foreach($r in $runs){ Run $r[0] $r[1] "gate" }
Run "shots_base" @() "shots"
$i=1; foreach($v in $variants){ Run "shots_v$i`_$($v[0])" @($v[1]) "shots"; $i++ }
L "ALL DONE"
