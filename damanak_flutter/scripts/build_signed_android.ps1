$ErrorActionPreference = 'Stop'

$damanakProjectRoot = Split-Path -Parent $PSScriptRoot
$damanakUserRoot = [Environment]::GetFolderPath('UserProfile')
$damanakSigningRoot = Join-Path $damanakUserRoot '.damanak-signing'
$damanakKeystorePath = Join-Path $damanakSigningRoot 'damanak-upload.jks'
$damanakCredentialPath = Join-Path $damanakSigningRoot 'damanak-upload.credential.xml'

if (-not (Test-Path -LiteralPath $damanakKeystorePath) -or
    -not (Test-Path -LiteralPath $damanakCredentialPath)) {
    throw 'ملفات توقيع ضمانك غير موجودة. أعد إنشاء مفتاح الرفع المحلي أولاً.'
}

$damanakCredential = Import-Clixml -LiteralPath $damanakCredentialPath
$damanakPassword = $damanakCredential.GetNetworkCredential().Password
$env:DAMANAK_KEYSTORE_PATH = $damanakKeystorePath
$env:DAMANAK_KEYSTORE_PASSWORD = $damanakPassword
$env:DAMANAK_KEY_ALIAS = 'damanak-upload'

Push-Location $damanakProjectRoot
try {
    flutter build appbundle --release @args
    flutter build apk --release @args
} finally {
    Pop-Location
    Remove-Item Env:DAMANAK_KEYSTORE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:DAMANAK_KEYSTORE_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:DAMANAK_KEY_ALIAS -ErrorAction SilentlyContinue
    $damanakPassword = $null
}
