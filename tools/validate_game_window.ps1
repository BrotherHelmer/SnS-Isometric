param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [string[]]$LaunchArguments = @(),
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [int]$Width = 1280,
    [int]$Height = 720,
    [int]$PlayButtonXPercent = 50,
    [int]$PlayButtonYPercent = 46,
    [int]$WarmupSeconds = 8,
    [int]$AfterClickSeconds = 6
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WindowProbe {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int command);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr insertAfter, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
}
"@

function Save-WindowImage {
    param([IntPtr]$Handle, [string]$Path)
    $rect = New-Object WindowProbe+RECT
    if (-not [WindowProbe]::GetClientRect($Handle, [ref]$rect)) {
        throw "Unable to read the game client bounds."
    }
    $origin = New-Object WindowProbe+POINT
    if (-not [WindowProbe]::ClientToScreen($Handle, [ref]$origin)) {
        throw "Unable to map the game client to the desktop."
    }
    $bitmap = New-Object System.Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        # OpenGL swap chains do not reliably support PrintWindow. The game is
        # foregrounded for this probe, so capture the actual desktop pixels.
        $graphics.CopyFromScreen(
            (New-Object System.Drawing.Point $origin.X, $origin.Y),
            [System.Drawing.Point]::Empty,
            $bitmap.Size
        )
    }
    finally {
        $graphics.Dispose()
    }
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

function Get-WindowHandle {
    param([System.Diagnostics.Process]$Process)
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "Game exited before creating its main window."
        }
        if ($Process.MainWindowHandle -ne [IntPtr]::Zero) {
            return $Process.MainWindowHandle
        }
        Start-Sleep -Milliseconds 100
    }
    throw "Game did not create a main window within ten seconds."
}

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null
$argumentList = @($LaunchArguments) + @("--resolution", "${Width}x${Height}")
$process = Start-Process -FilePath $Executable -ArgumentList $argumentList -PassThru
$windowHandle = Get-WindowHandle -Process $process
[void][WindowProbe]::ShowWindow($windowHandle, 5)
[void][WindowProbe]::SetWindowPos($windowHandle, [IntPtr](-1), 20, 20, $Width, $Height, 0x0040)
[void][WindowProbe]::SetForegroundWindow($windowHandle)
[void][WindowProbe]::BringWindowToTop($windowHandle)
Start-Sleep -Seconds $WarmupSeconds

$beforePath = Join-Path $resolvedOutput "menu_before_click.png"
Save-WindowImage -Handle $windowHandle -Path $beforePath

$client = New-Object WindowProbe+RECT
[void][WindowProbe]::GetClientRect($windowHandle, [ref]$client)
$clickX = [int](($client.Right - $client.Left) * $PlayButtonXPercent / 100.0)
$clickY = [int](($client.Bottom - $client.Top) * $PlayButtonYPercent / 100.0)
$packed = [IntPtr](($clickY -shl 16) -bor ($clickX -band 0xffff))
[void][WindowProbe]::PostMessage($windowHandle, 0x0200, [IntPtr]::Zero, $packed)
[void][WindowProbe]::PostMessage($windowHandle, 0x0201, [IntPtr]1, $packed)
[void][WindowProbe]::PostMessage($windowHandle, 0x0202, [IntPtr]::Zero, $packed)
Start-Sleep -Seconds $AfterClickSeconds

$process.Refresh()
if ($process.HasExited) {
    throw "Game exited after the Play Demo click."
}
$afterPath = Join-Path $resolvedOutput "opening_after_click.png"
Save-WindowImage -Handle $windowHandle -Path $afterPath

$beforeHash = (Get-FileHash -LiteralPath $beforePath -Algorithm SHA256).Hash
$afterHash = (Get-FileHash -LiteralPath $afterPath -Algorithm SHA256).Hash
$changed = $beforeHash -ne $afterHash
$report = @(
    "WINDOW_INPUT_VALIDATION"
    "process_alive_after_click=true"
    "frame_changed_after_click=$($changed.ToString().ToLowerInvariant())"
    "menu_capture=$beforePath"
    "opening_capture=$afterPath"
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText((Join-Path $resolvedOutput "validation_report.txt"), $report + [Environment]::NewLine)

if (-not $process.HasExited) {
    $process.CloseMainWindow() | Out-Null
    Start-Sleep -Milliseconds 600
    $process.Refresh()
    if (-not $process.HasExited) {
        $process.Kill()
    }
}

Write-Output $report
if (-not $changed) {
    exit 1
}
