# Pure fixture tests: no emulator, ADB, firewall, or account operations.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$tokens = $null
$parseErrors = $null
$scriptPath = Join-Path $PSScriptRoot 'ldplayer-control.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Control script syntax is invalid.' }
$functionNames = @('Assert-PortsAvailable', 'Test-GuestPortOwnership')
$definitions = @($ast.FindAll({
    param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in $functionNames
}, $false))
if ($definitions.Count -ne 2) { throw 'Expected two pure guard functions.' }
foreach ($definition in $definitions) { . ([scriptblock]::Create($definition.Extent.Text)) }

$seventh = [pscustomobject]@{ Instance = 7; Index = 6; EnginePid = 100 }
$first = [pscustomobject]@{ Instance = 1; Index = 0; EnginePid = 200 }
$foreign = [pscustomobject]@{ LocalPort = 5567; OwningProcess = 777 }
$owned = [pscustomobject]@{ LocalPort = 5567; OwningProcess = 100 }
$consoleCollision = [pscustomobject]@{ LocalPort = 5566; OwningProcess = 777 }

Assert-PortsAvailable @($first, $seventh) @()
Assert-PortsAvailable @($first) @($foreign)
$rejected = 0
foreach ($listener in @($foreign, $consoleCollision)) {
    try { Assert-PortsAvailable @($first, $seventh) @($listener) } catch {
        if ($_.Exception.Message -notmatch 'Instance 7 ports') { throw }
        $rejected++
    }
}
if ($rejected -ne 2) { throw 'Did not reject console and ADB collisions.' }
if (!(Test-GuestPortOwnership $seventh @($owned))) { throw 'Rejected correct port owner.' }
if (Test-GuestPortOwnership $seventh @($foreign)) { throw 'Accepted another emulator owner.' }
if (Test-GuestPortOwnership $seventh @($owned, $foreign)) { throw 'Accepted ambiguous ownership.' }
if (Test-GuestPortOwnership $seventh @()) { throw 'Accepted missing listener.' }
$noEngine = [pscustomobject]@{ Instance = 7; Index = 6; EnginePid = -1 }
if (Test-GuestPortOwnership $noEngine @($owned)) { throw 'Accepted missing engine.' }
'PASS: 9 port-isolation fixture checks; no emulator/account operations executed.'
