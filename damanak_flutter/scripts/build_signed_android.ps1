$ErrorActionPreference = 'Stop'

$damanakProjectRoot = Split-Path -Parent $PSScriptRoot
$damanakUserRoot = [Environment]::GetFolderPath('UserProfile')
$damanakSigningRoot = Join-Path $damanakUserRoot '.damanak\android'
$damanakKeystorePath = Join-Path $damanakSigningRoot 'damanak-upload-v2.p12'
$damanakCredentialPath = Join-Path $damanakSigningRoot 'damanak-upload-v2.password.dpapi'

if (-not (Test-Path -LiteralPath $damanakKeystorePath) -or
    -not (Test-Path -LiteralPath $damanakCredentialPath)) {
    throw 'Current Damanak Google Play signing files are missing.'
}

Add-Type -AssemblyName System.Security
$damanakProtectedHex = [IO.File]::ReadAllText($damanakCredentialPath).Trim()
if ($damanakProtectedHex.Length % 2 -ne 0) {
    throw 'The encrypted Damanak signing credential is invalid.'
}
$damanakProtectedBytes = New-Object byte[] ($damanakProtectedHex.Length / 2)
for ($index = 0; $index -lt $damanakProtectedBytes.Length; $index++) {
    $damanakProtectedBytes[$index] = [Convert]::ToByte(
        $damanakProtectedHex.Substring($index * 2, 2),
        16
    )
}
$damanakPasswordBytes = [Security.Cryptography.ProtectedData]::Unprotect(
    $damanakProtectedBytes,
    $null,
    [Security.Cryptography.DataProtectionScope]::CurrentUser
)
$damanakPassword = [Text.Encoding]::Unicode.GetString($damanakPasswordBytes).Trim([char]0).Trim()
if ([string]::IsNullOrWhiteSpace($damanakPassword)) {
    throw 'The Damanak signing credential could not be decrypted.'
}
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
    if ($null -ne $damanakPasswordBytes) {
        [Array]::Clear($damanakPasswordBytes, 0, $damanakPasswordBytes.Length)
    }
    if ($null -ne $damanakProtectedBytes) {
        [Array]::Clear($damanakProtectedBytes, 0, $damanakProtectedBytes.Length)
    }
}
