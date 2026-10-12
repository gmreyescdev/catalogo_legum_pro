# Compile the approved raster icon into native platform density resources.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path $PSScriptRoot -Parent
$source = [System.Drawing.Image]::FromFile((Join-Path $projectRoot 'assets/branding/legumpro-icon.png'))
function Write-Icon([string]$relativePath, [int]$size, [double]$contentScale = 1.0) {
    $destination = Join-Path $projectRoot $relativePath
    [System.IO.Directory]::CreateDirectory((Split-Path $destination -Parent)) | Out-Null
    $bitmap = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#0E1E1E'))
        $contentSize = [int]($size * $contentScale)
        $offset = [int](($size - $contentSize) / 2)
        $graphics.DrawImage($source, $offset, $offset, $contentSize, $contentSize)
        $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}
try {
    $densities = @{mdpi=1; hdpi=1.5; xhdpi=2; xxhdpi=3; xxxhdpi=4}
    foreach ($entry in $densities.GetEnumerator()) {
        Write-Icon "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher.png" ([int](48 * $entry.Value))
        Write-Icon "android/app/src/main/res/mipmap-$($entry.Key)/ic_launcher_foreground.png" ([int](108 * $entry.Value)) 0.8
    }
    $catalog = Get-Content (Join-Path $projectRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
    foreach ($entry in $catalog.images) {
        $points = [double]::Parse(($entry.size -split 'x')[0], [System.Globalization.CultureInfo]::InvariantCulture)
        $scale = [double]::Parse($entry.scale.TrimEnd('x'), [System.Globalization.CultureInfo]::InvariantCulture)
        Write-Icon "ios/Runner/Assets.xcassets/AppIcon.appiconset/$($entry.filename)" ([int]($points * $scale))
    }
} finally {
    $source.Dispose()
}
Write-Output 'Android and iOS icon resources generated.'
