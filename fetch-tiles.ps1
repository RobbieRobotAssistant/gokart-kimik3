param(
  [int]$z = 17,
  [double]$minLat = 39.0063320,
  [double]$minLon = -77.1415910,
  [double]$maxLat = 39.0242980,
  [double]$maxLon = -77.1184850,
  [string]$outDir = "C:\Users\raami\AppData\Local\Temp\opencode\tiles",
  [string]$outJpg = "satellite.jpg",
  [string]$outJson = "satbounds.json"
)
$ErrorActionPreference = 'Stop'

$n = [Math]::Pow(2, $z)
function LonToTileX($lon) { [Math]::Floor(($lon + 180) / 360 * $n) }
function LatToTileY($lat) {
  $r = $lat * [Math]::PI / 180
  [Math]::Floor((1 - [Math]::Log([Math]::Tan($r) + 1 / [Math]::Cos($r)) / [Math]::PI) / 2 * $n)
}
function TileXToLon($x) { $x / $n * 360 - 180 }
function TileYToLat($y) {
  $v = [Math]::PI * (1 - 2 * $y / $n)
  [Math]::ATan([Math]::Sinh($v)) * 180 / [Math]::PI
}

$x0 = LonToTileX $minLon; $x1 = LonToTileX $maxLon
$y0 = LatToTileY $maxLat; $y1 = LatToTileY $minLat
Write-Output "tiles: x $x0..$x1, y $y0..$y1  ($($x1-$x0+1) x $($y1-$y0+1))"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$dl = 0
for ($x = $x0; $x -le $x1; $x++) {
  for ($y = $y0; $y -le $y1; $y++) {
    $f = Join-Path $outDir "${x}_${y}.png"
    if (-not (Test-Path $f)) {
      $url = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x"
      curl.exe -s -m 30 -A "Mozilla/5.0" -o $f $url
      $dl++
    }
  }
}
Write-Output "downloaded: $dl"

Add-Type -AssemblyName System.Drawing
$cols = [int]($x1 - $x0 + 1); $rows = [int]($y1 - $y0 + 1)
$bmp = [System.Drawing.Bitmap]::new($cols * 256, $rows * 256)
$gr = [System.Drawing.Graphics]::FromImage($bmp)
for ($x = $x0; $x -le $x1; $x++) {
  for ($y = $y0; $y -le $y1; $y++) {
    $f = Join-Path $outDir "${x}_${y}.png"
    $img = [System.Drawing.Image]::FromFile($f)
    $gr.DrawImage($img, ($x - $x0) * 256, ($y - $y0) * 256, 256, 256)
    $img.Dispose()
  }
}
$gr.Dispose()

$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, 76)
$bmp.Save((Join-Path (Get-Location) $outJpg), $jpgCodec, $ep)
$bmp.Dispose()

$bounds = @{
  minLon = TileXToLon $x0
  maxLon = TileXToLon ($x1 + 1)
  maxLat = TileYToLat $y0
  minLat = TileYToLat ($y1 + 1)
  cols = $cols; rows = $rows; z = $z
} | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $outJson), $bounds)
Write-Output $bounds
Write-Output ("jpg size: " + (Get-Item $outJpg).Length)
