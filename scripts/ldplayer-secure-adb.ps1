# One-time, owner-approved inbound firewall protection. Does not enable ADB itself.
# Draft: corrected CIDR scopes passed parsing only; an elevated retry was blocked.
# Do not enable additional ADB endpoints until the effective rule is verified.
[CmdletBinding(SupportsShouldProcess = $true)]
param([Parameter(Mandatory = $true)][string]$ReportPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $ReportPath) { throw 'Report already exists; choose a new filename. Nothing was changed.' }
if (!(Test-Path -LiteralPath (Split-Path -Parent $ReportPath) -PathType Container)) {
    throw 'Report directory must already exist. Nothing was changed.'
}
$ruleName = 'VoiceBrief-LDPlayer-Local-ADB-v1'
$enginePath = 'C:\Program Files\ldplayer9box\Ld9BoxHeadless.exe'
$ports = @('2222', '5555-5577')
# Permit IPv4 loopback only. This is NOT a general LDPlayer network block.
$remoteAddresses = @(
    '0.0.0.0/2', '64.0.0.0/3', '96.0.0.0/4', '112.0.0.0/5',
    '120.0.0.0/6', '124.0.0.0/7', '126.0.0.0/8', '128.0.0.0/1',
    '::/1', '8000::/1'
)
$report = [ordered]@{ Succeeded = $false; RuleName = $ruleName; Created = $false; Error = $null }

try {
    if (!(Test-Path -LiteralPath $enginePath -PathType Leaf)) { throw 'Expected LDPlayer engine is missing.' }
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -and !$WhatIfPreference) {
        throw 'Administrator authorization is required; nothing was changed.'
    }
    $profiles = @(Get-NetFirewallProfile -PolicyStore ActiveStore)
    if ($profiles.Count -ne 3 -or @($profiles | Where-Object { $_.Enabled.ToString() -ne 'True' }).Count) {
        throw 'All Windows firewall profiles must already be enabled.'
    }
    if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
        throw 'The named rule already exists. Inspect it; this script never overwrites an existing rule.'
    }
    if ($PSCmdlet.ShouldProcess('LDPlayer engine TCP management ports only', 'Block inbound non-loopback IPv4 and all IPv6')) {
        New-NetFirewallRule -Name $ruleName -DisplayName 'VoiceBrief - LDPlayer local ADB only' `
            -Description 'Owner-approved local terminal diagnostics. Blocks network access to LDPlayer TCP management ports; leaves outgoing internet and IPv4 loopback intact.' `
            -Direction Inbound -Action Block -Enabled True -Profile Any -Protocol TCP `
            -Program $enginePath -LocalPort $ports -RemoteAddress $remoteAddresses `
            -EdgeTraversalPolicy Block -PolicyStore PersistentStore | Out-Null
        $report.Created = $true
        $rule = Get-NetFirewallRule -Name $ruleName -PolicyStore ActiveStore
        $application = $rule | Get-NetFirewallApplicationFilter
        $portFilter = $rule | Get-NetFirewallPortFilter
        $addressFilter = $rule | Get-NetFirewallAddressFilter
        if ($rule.Action.ToString() -ne 'Block' -or $rule.Direction.ToString() -ne 'Inbound' `
            -or $rule.Enabled.ToString() -ne 'True' -or $rule.Profile.ToString() -ne 'Any' `
            -or $application.Program -ine $enginePath `
            -or $portFilter.Protocol.ToString() -notin @('TCP', '6') `
            -or @(Compare-Object ($ports | Sort-Object) ($portFilter.LocalPort | Sort-Object)).Count `
            -or @(Compare-Object ($remoteAddresses | Sort-Object) ($addressFilter.RemoteAddress | Sort-Object)).Count) {
            throw 'Created rule verification failed. Do not enable additional ADB endpoints.'
        }
        $report.Succeeded = $true
    }
} catch {
    $report.Error = $_.Exception.Message
} finally {
    $report.TimestampUTC = [DateTime]::UtcNow.ToString('o')
    $report | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
}
if (!$report.Succeeded -and !$WhatIfPreference) { exit 1 }
