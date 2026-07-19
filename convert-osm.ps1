param(
  [string]$in = "osm_raw.xml",
  [string]$out = "map.json",
  [string]$lat0 = "39.0153150",
  [string]$lon0 = "-77.1300383"
)

$ErrorActionPreference = 'Stop'

$settings = New-Object System.Xml.XmlReaderSettings
$settings.IgnoreWhitespace = $true
$reader = [System.Xml.XmlReader]::Create((Resolve-Path $in).Path, $settings)

$nodes = @{}
$trees = New-Object 'System.Collections.Generic.List[string]'
$ways  = New-Object 'System.Collections.Generic.List[object]'

$keepKeys = @{}
foreach ($k in @('highway','building','building:levels','name','service','area','layer')) { $keepKeys[$k] = $true }

$curNodeId = $null; $curNodeLat = $null; $curNodeLon = $null; $nodeTags = $null
$curWay = $null

function Json-Escape([string]$s) {
  if ($null -eq $s) { return '' }
  $s = $s.Replace('\', '\\').Replace('"', '\"')
  $s = $s.Replace('&', '\u0026').Replace('<', '\u003c').Replace('>', '\u003e')
  $s = $s -replace "[`r`n]", ' '
  return $s
}

while ($reader.Read()) {
  if ($reader.NodeType -eq [System.Xml.XmlNodeType]::Element) {
    switch ($reader.Name) {
      'node' {
        $curNodeId  = $reader.GetAttribute('id')
        $curNodeLat = $reader.GetAttribute('lat')
        $curNodeLon = $reader.GetAttribute('lon')
        $nodes[$curNodeId] = "$curNodeLat,$curNodeLon"
        if ($reader.IsEmptyElement) { $nodeTags = $null } else { $nodeTags = @{} }
      }
      'tag' {
        $k = $reader.GetAttribute('k')
        if ($null -ne $curWay) {
          if ($keepKeys.ContainsKey($k)) { $curWay.Tags[$k] = $reader.GetAttribute('v') }
        } elseif ($null -ne $nodeTags) {
          $nodeTags[$k] = $reader.GetAttribute('v')
        }
      }
      'way' {
        $curWay = @{ Refs = (New-Object 'System.Collections.Generic.List[string]'); Tags = @{} }
      }
      'nd' {
        if ($null -ne $curWay) { $curWay.Refs.Add($reader.GetAttribute('ref')) }
      }
    }
  } elseif ($reader.NodeType -eq [System.Xml.XmlNodeType]::EndElement) {
    switch ($reader.Name) {
      'node' {
        if ($null -ne $nodeTags -and $nodeTags['natural'] -eq 'tree') {
          $trees.Add("$curNodeLat,$curNodeLon")
        }
        $nodeTags = $null
      }
      'way' {
        if ($curWay.Tags.ContainsKey('highway') -or $curWay.Tags.ContainsKey('building')) {
          $ways.Add($curWay)
        }
        $curWay = $null
      }
    }
  }
}
$reader.Close()

$used = @{}
foreach ($w in $ways) { foreach ($r in $w.Refs) { $used[$r] = $true } }

$sb = New-Object System.Text.StringBuilder 4000000
[void]$sb.Append('{"center":[').Append($lat0).Append(',').Append($lon0).Append('],"nodes":{')
$first = $true
foreach ($id in $used.Keys) {
  $ll = $nodes[$id]
  if (-not $ll) { continue }
  if ($first) { $first = $false } else { [void]$sb.Append(',') }
  [void]$sb.Append('"').Append($id).Append('":[').Append($ll).Append(']')
}
[void]$sb.Append('},"ways":[')
$first = $true
foreach ($w in $ways) {
  if ($first) { $first = $false } else { [void]$sb.Append(',') }
  [void]$sb.Append('{"r":[')
  $rf = $true
  foreach ($r in $w.Refs) {
    if (-not $nodes.ContainsKey($r)) { continue }
    if ($rf) { $rf = $false } else { [void]$sb.Append(',') }
    [void]$sb.Append($r)
  }
  [void]$sb.Append('],"t":{')
  $tf = $true
  foreach ($k in $w.Tags.Keys) {
    if ($tf) { $tf = $false } else { [void]$sb.Append(',') }
    [void]$sb.Append('"').Append((Json-Escape $k)).Append('":"').Append((Json-Escape $w.Tags[$k])).Append('"')
  }
  [void]$sb.Append('}}')
}
[void]$sb.Append('],"trees":[')
$first = $true
foreach ($t in $trees) {
  if ($first) { $first = $false } else { [void]$sb.Append(',') }
  [void]$sb.Append('[').Append($t).Append(']')
}
[void]$sb.Append(']}')

[System.IO.File]::WriteAllText((Join-Path (Get-Location) $out), $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

$hw = 0; $bd = 0
foreach ($w in $ways) { if ($w.Tags.ContainsKey('highway')) { $hw++ } else { $bd++ } }
Write-Output "ways: $($ways.Count) (roads: $hw, buildings: $bd), nodes used: $($used.Count), trees: $($trees.Count)"
Write-Output "map.json size: $((Get-Item $out).Length) bytes"
