param(
    [string]$Source = "assets/settlement/rivalry/sovereign_hero.png",
    [string]$Destination = "assets/settlement/rivalry/sovereign_walk_v3.png"
)

Add-Type -AssemblyName System.Drawing
$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$destinationPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Destination))
$sourceImage = [System.Drawing.Bitmap]::FromFile($sourcePath)
$sheet = New-Object System.Drawing.Bitmap ($sourceImage.Width * 4), $sourceImage.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sheet.SetResolution($sourceImage.HorizontalResolution, $sourceImage.VerticalResolution)

$bodyOffsets = @(0, -1, 0, -1)
$legOffsets = @(-1, 1, 1, -1)
for ($frame = 0; $frame -lt 4; $frame++) {
    $graphics = [System.Drawing.Graphics]::FromImage($sheet)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $targetX = $frame * $sourceImage.Width
    $upperSource = New-Object System.Drawing.Rectangle 0, 0, $sourceImage.Width, 49
    $upperTarget = New-Object System.Drawing.Rectangle $targetX, $bodyOffsets[$frame], $sourceImage.Width, 49
    $graphics.DrawImage($sourceImage, $upperTarget, $upperSource, [System.Drawing.GraphicsUnit]::Pixel)
    $leftSource = New-Object System.Drawing.Rectangle 0, 49, ([int]($sourceImage.Width / 2)), ($sourceImage.Height - 49)
    $leftTarget = New-Object System.Drawing.Rectangle ($targetX + $legOffsets[$frame]), (49 + $bodyOffsets[$frame]), $leftSource.Width, $leftSource.Height
    $graphics.DrawImage($sourceImage, $leftTarget, $leftSource, [System.Drawing.GraphicsUnit]::Pixel)
    $rightSource = New-Object System.Drawing.Rectangle ([int]($sourceImage.Width / 2)), 49, ([int]($sourceImage.Width / 2)), ($sourceImage.Height - 49)
    $rightTarget = New-Object System.Drawing.Rectangle ($targetX + $rightSource.X - $legOffsets[$frame]), (49 + $bodyOffsets[$frame]), $rightSource.Width, $rightSource.Height
    $graphics.DrawImage($sourceImage, $rightTarget, $rightSource, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
}

$destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)
[System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
$sheet.Save($destinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
$sourceImage.Dispose()
Write-Output "Generated $destinationPath"
