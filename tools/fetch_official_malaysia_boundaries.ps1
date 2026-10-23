param(
  [ValidateSet('all', 'state', 'district', 'mukim')]
  [string]$Layer = 'all',
  [string]$OutputDirectory = 'data/gis/raw'
)

$sources = @{
  state = @{
    Name = 'MyGOS Admin1'
    Url = 'https://mygos.mygeoportal.gov.my/gisserver/rest/services/UPI/UPI/MapServer/0/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson&outSR=4326'
  }
  district = @{
    Name = 'MyGOS Admin2'
    Url = 'https://mygos.mygeoportal.gov.my/gisserver/rest/services/UPI/UPI/MapServer/1/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson&outSR=4326'
  }
  mukim = @{
    Name = 'PlanMalaysia Mukim'
    Url = 'https://scharms.planmalaysia.gov.my/arcgis/rest/services/SCHARMS/MobileLayer/MapServer/4/query?where=1%3D1&outFields=*&returnGeometry=true&f=geojson&outSR=4326'
  }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$layers = if ($Layer -eq 'all') { @('state', 'district', 'mukim') } else { @($Layer) }
$manifest = @()

foreach ($selectedLayer in $layers) {
  $source = $sources[$selectedLayer]
  $outputPath = Join-Path $OutputDirectory "malaysia-$selectedLayer-$timestamp.geojson"
  $countUrl = $source.Url -replace 'outFields=\*&returnGeometry=true&f=geojson&outSR=4326', 'returnCountOnly=true&f=json'
  $expectedCount = (Invoke-RestMethod -Uri $countUrl -TimeoutSec 30).count
  $count = 0
  for ($attempt = 1; $attempt -le 3 -and $count -ne $expectedCount; $attempt++) {
    Invoke-WebRequest -Uri $source.Url -OutFile $outputPath -TimeoutSec 120
    $geoJson = Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json
    $count = if ($geoJson.type -eq 'FeatureCollection' -and $null -ne $geoJson.features) {
      @($geoJson.features).Count
    } else {
      0
    }
  }
  if ($count -ne $expectedCount) {
    Remove-Item -LiteralPath $outputPath
    throw "Incomplete $selectedLayer download from $($source.Name): expected $expectedCount feature(s), received $count."
  }
  $manifest += [PSCustomObject]@{
    layer = $selectedLayer
    source_name = $source.Name
    source_url = $source.Url
    downloaded_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    file = $outputPath
    feature_count = $count
    import_status = 'reference_only_requires_township_review'
  }
  Write-Output "Downloaded $count $selectedLayer feature(s) from $($source.Name)."
}

$manifestPath = Join-Path $OutputDirectory "malaysia-official-boundaries-$timestamp.manifest.json"
$manifest | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Write-Output "Review manifest: $manifestPath"
