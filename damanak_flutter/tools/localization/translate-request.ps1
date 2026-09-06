param([Parameter(Mandatory=$true)][string]$Url)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$parsed = [Uri]$Url
if ($parsed.Scheme -ne 'https' -or $parsed.Host -ne 'translate.googleapis.com') {
  throw 'Unexpected translation endpoint'
}
$response = Invoke-WebRequest -Uri $Url -TimeoutSec 25
[Console]::Write($response.Content)
