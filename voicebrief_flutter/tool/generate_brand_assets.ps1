param(
  [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\assets\brand')
)

Add-Type -AssemblyName System.Drawing

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null

function New-VoiceBriefMark {
  param(
    [int]$Size,
    [System.Drawing.Color]$Background,
    [System.Drawing.Color]$Signal,
    [System.Drawing.Color]$Quiet,
    [bool]$TransparentBackground,
    [string]$Path
  )

  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  if ($TransparentBackground) {
    $graphics.Clear([System.Drawing.Color]::Transparent)
  } else {
    $graphics.Clear($Background)
  }

  $unit = $Size / 16.0
  $barWidth = [Math]::Round($unit * 1.45)
  $gap = [Math]::Round($unit * 1.15)
  $heights = @(
    ($unit * 3.8),
    ($unit * 6.8),
    ($unit * 10.2),
    ($unit * 6.8),
    ($unit * 3.8)
  )
  $total = ($barWidth * 5) + ($gap * 4)
  $startX = ($Size - $total) / 2.0
  for ($index = 0; $index -lt 5; $index++) {
    $height = $heights[$index]
    $x = $startX + (($barWidth + $gap) * $index)
    $y = ($Size - $height) / 2.0
    $radius = $barWidth / 2.0
    $pathShape = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pathShape.AddArc($x, $y, $barWidth, $barWidth, 180, 180)
    $pathShape.AddLine($x + $barWidth, $y + $radius, $x + $barWidth, $y + $height - $radius)
    $pathShape.AddArc($x, $y + $height - $barWidth, $barWidth, $barWidth, 0, 180)
    $pathShape.AddLine($x, $y + $height - $radius, $x, $y + $radius)
    $pathShape.CloseFigure()
    $color = if ($index -eq 2) { $Signal } else { $Quiet }
    $brush = New-Object System.Drawing.SolidBrush($color)
    $graphics.FillPath($brush, $pathShape)
    $brush.Dispose()
    $pathShape.Dispose()
  }

  $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
}

$black = [System.Drawing.ColorTranslator]::FromHtml('#090909')
$white = [System.Drawing.ColorTranslator]::FromHtml('#FFFFFF')
$blue = [System.Drawing.ColorTranslator]::FromHtml('#007AFF')

New-VoiceBriefMark -Size 1024 -Background $black -Signal $blue -Quiet $white -TransparentBackground $false -Path (Join-Path $resolvedOutput 'voicebrief_icon.png')
New-VoiceBriefMark -Size 1024 -Background $black -Signal $blue -Quiet $white -TransparentBackground $true -Path (Join-Path $resolvedOutput 'voicebrief_icon_foreground.png')
New-VoiceBriefMark -Size 256 -Background $white -Signal $blue -Quiet $black -TransparentBackground $true -Path (Join-Path $resolvedOutput 'voicebrief_mark.png')
New-VoiceBriefMark -Size 256 -Background $black -Signal ([System.Drawing.ColorTranslator]::FromHtml('#0A84FF')) -Quiet $white -TransparentBackground $true -Path (Join-Path $resolvedOutput 'voicebrief_mark_dark.png')
