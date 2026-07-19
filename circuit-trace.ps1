param(
  [string]$map = "map.json",
  [string]$out = "circuit.json",
  [double]$homeLat = 39.0153150,
  [double]$homeLon = -77.1300383
)
$ErrorActionPreference = 'Stop'
$j = Get-Content $map -Raw | ConvertFrom-Json

$lat0 = $homeLat; $lon0 = $homeLon
$rlon = 111320 * [Math]::Cos($lat0 * [Math]::PI / 180)
$nodes = @{}
foreach ($p in $j.nodes.PSObject.Properties) {
  $nodes[$p.Name] = @([double]$p.Value[0], [double]$p.Value[1])
}
function PX($id) { ($nodes[$id][1] - $lon0) * $rlon }
function PZ($id) { -($nodes[$id][0] - $lat0) * 111320 }

$loop = @('Montauk Avenue', 'Stoneham Road', 'Ashburton Lane', 'Lone Oak Drive')

$AdjMap = @{}
$AdjMap['*'] = @{}
$AM = $AdjMap['*']
$nodeNames = @{}
foreach ($w in $j.ways) {
  $hw = $w.t.highway; $nm = $w.t.name
  if (-not $hw) { continue }
  if ($hw -in @('footway','path','cycleway','steps','service','track')) { continue }
  if ($nm) {
    foreach ($r in $w.r) {
      $rs = [string]$r
      if (-not $nodeNames.ContainsKey($rs)) { $nodeNames[$rs] = @{} }
      $nodeNames[$rs][$nm] = $true
    }
  }
  for ($i = 0; $i -lt $w.r.Count - 1; $i++) {
    $na = [string]$w.r[$i]; $nb = [string]$w.r[$i+1]
    if (-not $nodes.ContainsKey($na) -or -not $nodes.ContainsKey($nb)) { continue }
    $dx = (PX $na) - (PX $nb); $dz = (PZ $na) - (PZ $nb)
    $dd = [Math]::Sqrt($dx*$dx + $dz*$dz)
    if ($dd -lt 0.01) { continue }
    if (-not $AM.ContainsKey($na)) { $AM[$na] = New-Object 'System.Collections.Generic.List[object]' }
    if (-not $AM.ContainsKey($nb)) { $AM[$nb] = New-Object 'System.Collections.Generic.List[object]' }
    $AM[$na].Add(@($nb, $dd)); $AM[$nb].Add(@($na, $dd))
  }
}

$ints = @()
for ($i = 0; $i -lt 4; $i++) {
  $s1 = $loop[$i]; $s2 = $loop[($i+1) % 4]
  $shared = @()
  foreach ($r in $nodeNames.Keys) {
    if ($nodeNames[$r].ContainsKey($s1) -and $nodeNames[$r].ContainsKey($s2)) { $shared += $r }
  }
  if ($shared.Count -ne 1) { throw "Intersection $s1 x $s2 has $($shared.Count) nodes" }
  $ints += $shared[0]
}

function Dijkstra($AM, $startId, $goalId) {
  $dist = @{}; $prev = @{}; $visited = @{}
  $dist[$startId] = 0.0
  while ($true) {
    $u = $null; $best = [double]::MaxValue
    foreach ($k in $dist.Keys) {
      if (-not $visited.ContainsKey($k) -and $dist[$k] -lt $best) { $best = $dist[$k]; $u = $k }
    }
    if ($null -eq $u) { break }
    if ($u -eq $goalId) { break }
    $visited[$u] = $true
    if (-not $AM.ContainsKey($u)) { continue }
    foreach ($e in $AM[$u]) {
      $v = $e[0]; $nd = $dist[$u] + $e[1]
      if (-not $dist.ContainsKey($v) -or $nd -lt $dist[$v]) { $dist[$v] = $nd; $prev[$v] = $u }
    }
  }
  $path = New-Object 'System.Collections.Generic.List[string]'
  $cur = $goalId
  while ($cur -ne $startId) { $path.Insert(0, $cur); $cur = $prev[$cur]; if ($null -eq $cur) { throw "no path" } }
  $path.Insert(0, $startId)
  return ,$path
}

$full = New-Object 'System.Collections.Generic.List[string]'
for ($i = 0; $i -lt 4; $i++) {
  $street = $loop[$i]
  $fromId = $ints[($i+3) % 4]
  $toId = $ints[$i]
  $path = Dijkstra $AM $fromId $toId
  for ($k = 0; $k -lt $path.Count; $k++) {
    if ($full.Count -eq 0 -or $full[$full.Count-1] -ne $path[$k]) { $full.Add($path[$k]) }
  }
}

$pts = New-Object 'System.Collections.Generic.List[double[]]'
foreach ($id in $full) {
  $px = [double](PX $id)
  $pz = [double](PZ $id)
  $pts.Add([double[]]@($px, $pz))
}
$total = 0.0
for ($i = 0; $i -lt $pts.Count; $i++) {
  $p1 = $pts[$i]; $p2 = $pts[($i+1) % $pts.Count]
  $total += [Math]::Sqrt(($p1[0]-$p2[0])*($p1[0]-$p2[0]) + ($p1[1]-$p2[1])*($p1[1]-$p2[1]))
}

$spacing = 35.0
$gates = New-Object 'System.Collections.Generic.List[double[]]'
$acc = 0.0; $nextAt = 0.0
for ($i = 0; $i -lt $pts.Count; $i++) {
  $p1 = $pts[$i]; $p2 = $pts[($i+1) % $pts.Count]
  $segLen = [Math]::Sqrt(($p1[0]-$p2[0])*($p1[0]-$p2[0]) + ($p1[1]-$p2[1])*($p1[1]-$p2[1]))
  while ($acc + $segLen -ge $nextAt) {
    $t = ($nextAt - $acc) / $segLen
    $gx = $p1[0] + ($p2[0]-$p1[0]) * $t
    $gz = $p1[1] + ($p2[1]-$p1[1]) * $t
    $gates.Add([double[]]@($gx, $gz))
    $nextAt += $spacing
  }
  $acc += $segLen
}

$bestIdx = 0; $bestD = [double]::MaxValue
for ($i = 0; $i -lt $gates.Count; $i++) {
  $d2 = $gates[$i][0]*$gates[$i][0] + $gates[$i][1]*$gates[$i][1]
  if ($d2 -lt $bestD) { $bestD = $d2; $bestIdx = $i }
}
$rot = New-Object 'System.Collections.Generic.List[double[]]'
for ($k = 0; $k -lt $gates.Count; $k++) { $rot.Add($gates[($bestIdx + $k) % $gates.Count]) }

$inv = [Globalization.CultureInfo]::InvariantCulture
$sbOut = New-Object System.Text.StringBuilder
[void]$sbOut.Append('{"length":').Append([int]$total).Append(',"gates":[')
for ($i = 0; $i -lt $rot.Count; $i++) {
  if ($i -gt 0) { [void]$sbOut.Append(',') }
  $glon = ($rot[$i][0] / $rlon) + $lon0
  $glat = $lat0 - ($rot[$i][1] / 111320)
  [void]$sbOut.Append('[').Append($glon.ToString('F7', $inv)).Append(',').Append($glat.ToString('F7', $inv)).Append(']')
}
[void]$sbOut.Append(']}')
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $sbOut.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "loop length: $([int]$total) m, gates: $($rot.Count)"
Write-Output "gate0 lat,lon: $($lat0 - ($rot[0][1] / 111320)), $(($rot[0][0] / $rlon) + $lon0)"
