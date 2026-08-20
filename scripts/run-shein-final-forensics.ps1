[CmdletBinding()]
param(
    [ValidateSet('A1', 'A2', 'A3', 'A4', 'B0', 'B1', 'B2', 'B3')]
    [string]$Scenario,
    [string]$ExpectedVersion = '86.206',
    [string]$ExpectedBuild = '1068',
    [string]$Udid = '00008140-001E6D581E11801C'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$ArtifactsRoot = Join-Path $RepositoryRoot 'artifacts\shein-final-forensics'
$Pmd = 'C:\Users\MOHAMMAD\.codex\tools\ios-usb-diagnostics\Scripts\pymobiledevice3.exe'
$BundleId = 'com.otlobli.app'
$ScenarioFileName = 'shein-final-forensics-scenario.json'
$ScenarioModes = [ordered]@{
    A1 = 'RAW'
    A2 = 'RAW'
    A3 = 'RAW'
    A4 = 'RAW_WITH_CACHE_GUARD'
    B0 = 'RAW'
    B1 = 'CAPTURE_ONLY'
    B2 = 'BLOCKING_ONLY'
    B3 = 'CAPTURE_AND_BLOCKING'
}

function Write-Phase {
    param([string]$Text)
    Write-Host "`n[$Text]" -ForegroundColor Cyan
}

function ConvertFrom-PmdJson {
    param([string[]]$Arguments)
    $raw = (& $Pmd @Arguments 2>$null | Out-String).Trim()
    if (-not $raw) { throw "pymobiledevice3 returned no JSON for: $($Arguments -join ' ')" }
    return $raw | ConvertFrom-Json -AsHashtable
}

function Write-JsonFile {
    param([string]$Path, [object]$Value)
    $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Add-JsonLine {
    param([string]$Path, [object]$Value)
    $line = $Value | ConvertTo-Json -Depth 20 -Compress
    Add-Content -LiteralPath $Path -Value $line -Encoding utf8
}

function Get-AppPid {
    $raw = (& $Pmd developer dvt process-id-for-bundle-id $BundleId --userspace --udid $Udid 2>$null | Out-String)
    $matches = [regex]::Matches($raw, '(?m)^\s*(\d+)\s*$')
    if ($matches.Count -eq 0) { return 0 }
    return [int]$matches[$matches.Count - 1].Groups[1].Value
}

function Get-RelevantProcesses {
    try {
        $processes = ConvertFrom-PmdJson @('processes', 'ps', '--udid', $Udid)
        $relevant = @()
        foreach ($entry in $processes.GetEnumerator()) {
            $name = [string]$entry.Value.ProcessName
            if ($name -eq 'App' -or $name -like '*WebContent*' -or $name -like '*Networking*' -or $name -like '*GPU*') {
                $relevant += [ordered]@{ pid = [int]$entry.Key; processName = $name }
            }
        }
        return $relevant
    } catch {
        return @([ordered]@{ error = $_.Exception.Message })
    }
}

function Save-Screenshot {
    param([string]$Marker)
    $target = Join-Path $ScreenshotsDirectory ("{0:D2}-{1}.png" -f $script:MarkerSequence, $Marker.ToLowerInvariant())
    try {
        & $Pmd developer dvt screenshot $target --userspace --udid $Udid 2>$null | Out-Null
        return $target
    } catch {
        Add-JsonLine $ControllerEvents ([ordered]@{
            at = [DateTimeOffset]::UtcNow.ToString('o')
            event = 'screenshot-failed'
            marker = $Marker
            error = $_.Exception.Message
        })
        return $null
    }
}

function Write-Marker {
    param([string]$Name, [string]$Instruction)
    if ($Instruction) {
        Write-Host $Instruction -ForegroundColor Yellow
        [void](Read-Host 'اضغط Enter بعد تنفيذ الخطوة')
    }
    $script:MarkerSequence += 1
    $pid = Get-AppPid
    $screenshot = Save-Screenshot $Name
    Add-JsonLine $MarkersPath ([ordered]@{
        at = [DateTimeOffset]::UtcNow.ToString('o')
        marker = $Name
        scenario = $Scenario
        mode = $Mode
        runId = $RunId
        websiteDataContainer = $ContainerIdentifier
        appPid = $pid
        relevantProcesses = @(Get-RelevantProcesses)
        screenshot = if ($screenshot) { Split-Path -Leaf $screenshot } else { $null }
    })
    return $pid
}

function Read-OutcomeMarker {
    $result = (Read-Host 'اكتب WORKING إذا بقي التصفح يعمل، أو FROZEN إذا ظهر التجمّد').Trim().ToUpperInvariant()
    while ($result -notin @('WORKING', 'FROZEN')) {
        $result = (Read-Host 'القيمة المطلوبة فقط: WORKING أو FROZEN').Trim().ToUpperInvariant()
    }
    if ($result -eq 'FROZEN') {
        [void](Write-Marker 'FREEZE_VISIBLE' '')
    } else {
        [void](Write-Marker 'SECOND_WORKING_CONFIRMED' '')
    }
    return $result
}

function Assert-AppStopped {
    param([int]$PreviousPid)
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds(25)
    do {
        $current = Get-AppPid
        if ($current -eq 0 -or $current -ne $PreviousPid) { return $true }
        Start-Sleep -Milliseconds 750
    } while ([DateTimeOffset]::UtcNow -lt $deadline)
    throw "APP_KILLED was marked but the previous Otlobli PID $PreviousPid is still alive."
}

function Stop-CaptureProcess {
    param([System.Diagnostics.Process]$Process, [string]$Name)
    if ($null -eq $Process) { return }
    try {
        if (-not $Process.HasExited) {
            Stop-Process -Id $Process.Id -ErrorAction Stop
            $Process.WaitForExit(5000) | Out-Null
        }
    } catch {
        Add-JsonLine $ControllerEvents ([ordered]@{
            at = [DateTimeOffset]::UtcNow.ToString('o')
            event = 'capture-process-stop-failed'
            process = $Name
            pid = $Process.Id
            error = $_.Exception.Message
        })
    }
}

if (-not (Test-Path -LiteralPath $Pmd -PathType Leaf)) {
    throw "Required pymobiledevice3 10.10.0 executable is missing: $Pmd"
}

if (-not $Scenario) {
    Write-Host 'اختر السيناريو:' -ForegroundColor Cyan
    Write-Host '  A1 RAW hide/show'
    Write-Host '  A2 RAW background/foreground'
    Write-Host '  A3 RAW kill/cold launch'
    Write-Host '  A4 RAW + CACHE GUARD kill/cold launch'
    Write-Host '  B0 RAW first entry'
    Write-Host '  B1 CAPTURE ONLY first entry'
    Write-Host '  B2 BLOCKING ONLY first entry'
    Write-Host '  B3 CAPTURE + BLOCKING first entry'
    $Scenario = (Read-Host 'Scenario').Trim().ToUpperInvariant()
    if (-not $ScenarioModes.Contains($Scenario)) { throw "Unsupported scenario: $Scenario" }
}

$Mode = [string]$ScenarioModes[$Scenario]
$RunId = [guid]::NewGuid().ToString().ToLowerInvariant()
$ContainerIdentifier = [guid]::NewGuid().ToString().ToLowerInvariant()
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$EvidenceDirectory = Join-Path $ArtifactsRoot "$Timestamp-$($Scenario.ToLowerInvariant())"
$ScreenshotsDirectory = Join-Path $EvidenceDirectory 'screenshots'
$CacheDirectory = Join-Path $EvidenceDirectory 'cache-records'
$MarkersPath = Join-Path $EvidenceDirectory 'operator-markers.jsonl'
$ProcessesPath = Join-Path $EvidenceDirectory 'processes.jsonl'
$ControllerEvents = Join-Path $EvidenceDirectory 'controller-events.jsonl'
$UnifiedPath = Join-Path $EvidenceDirectory 'unified.log'
$RuntimePath = Join-Path $EvidenceDirectory 'runtime.jsonl'
$CdpPath = Join-Path $EvidenceDirectory 'cdp-network.jsonl'
$ManifestPath = Join-Path $EvidenceDirectory 'manifest.json'
$StopFile = Join-Path $EvidenceDirectory '.stop-cdp-capture'
$RegistryPath = Join-Path $ArtifactsRoot 'scenario-registry.json'
$ScenarioConfigPath = Join-Path $EvidenceDirectory $ScenarioFileName
$script:MarkerSequence = 0

New-Item -ItemType Directory -Path $ScreenshotsDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $CacheDirectory -Force | Out-Null

Write-Phase 'PREFLIGHT'
$toolVersion = (& $Pmd version 2>$null | Out-String).Trim()
if ($toolVersion -ne '10.10.0') { throw "Expected pymobiledevice3 10.10.0, got $toolVersion" }

$devices = @(ConvertFrom-PmdJson @('usbmux', 'list'))
$device = @($devices | Where-Object { $_.UniqueDeviceID -eq $Udid -and $_.ConnectionType -eq 'USB' })
if ($device.Count -ne 1) { throw "Expected exactly one USB device with UDID $Udid" }

$appQuery = ConvertFrom-PmdJson @('apps', 'query', $BundleId, '--udid', $Udid)
$app = $appQuery[$BundleId]
if ($null -eq $app) { throw "$BundleId is not installed" }
if ([string]$app.CFBundleShortVersionString -ne $ExpectedVersion -or [string]$app.CFBundleVersion -ne $ExpectedBuild) {
    throw "Installed Otlobli is $($app.CFBundleShortVersionString)/$($app.CFBundleVersion); expected $ExpectedVersion/$ExpectedBuild"
}

$mounted = @(ConvertFrom-PmdJson @('mounter', 'list', '--udid', $Udid) | Where-Object {
    $_.IsMounted -eq $true -and $_.MountPath -eq '/System/Developer'
})
if ($mounted.Count -lt 1) { throw 'DeveloperDiskImage is not mounted at /System/Developer' }

$registry = @()
if (Test-Path -LiteralPath $RegistryPath) {
    $registry = @(Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json -AsHashtable)
}
if ($registry | Where-Object { $_.containerIdentifier -eq $ContainerIdentifier }) {
    throw 'Generated container identifier unexpectedly already exists in the scenario registry'
}
$registry += [ordered]@{
    scenario = $Scenario
    mode = $Mode
    runId = $RunId
    containerIdentifier = $ContainerIdentifier
    createdAt = [DateTimeOffset]::UtcNow.ToString('o')
    evidenceDirectory = Split-Path -Leaf $EvidenceDirectory
}
Write-JsonFile $RegistryPath $registry

$scenarioConfig = [ordered]@{
    schemaVersion = 1
    scenario = $Scenario
    mode = $Mode
    containerIdentifier = $ContainerIdentifier
    runId = $RunId
    createdAt = [DateTimeOffset]::UtcNow.ToString('o')
}
Write-JsonFile $ScenarioConfigPath $scenarioConfig

$manifest = [ordered]@{
    schemaVersion = 1
    createdAt = [DateTimeOffset]::UtcNow.ToString('o')
    repository = $RepositoryRoot
    branch = (& git -C $RepositoryRoot branch --show-current | Out-String).Trim()
    commit = (& git -C $RepositoryRoot rev-parse HEAD | Out-String).Trim()
    device = [ordered]@{
        udid = $Udid
        productType = $device[0].ProductType
        productVersion = $device[0].ProductVersion
        buildVersion = $device[0].BuildVersion
        connectionType = $device[0].ConnectionType
    }
    installed = [ordered]@{ bundleId = $BundleId; version = $ExpectedVersion; build = $ExpectedBuild }
    tool = [ordered]@{ pymobiledevice3 = $toolVersion; developerDiskImageMounted = $true }
    scenario = $Scenario
    mode = $Mode
    runId = $RunId
    websiteDataContainer = $ContainerIdentifier
    websiteDataMutation = $false
    cacheClear = $false
    appKillAuthorized = $Scenario -in @('A3', 'A4')
}
Write-JsonFile $ManifestPath $manifest

& $Pmd apps push $BundleId $ScenarioConfigPath $ScenarioFileName --documents --udid $Udid 2>$null | Out-Null

Write-Phase 'CAPTURE START'
$syslogError = Join-Path $EvidenceDirectory 'unified.stderr.log'
$cdpBridgeOut = Join-Path $EvidenceDirectory 'cdp-bridge.log'
$cdpBridgeError = Join-Path $EvidenceDirectory 'cdp-bridge.stderr.log'
$cdpRecorderError = Join-Path $EvidenceDirectory 'cdp-recorder.stderr.log'

$syslogProcess = Start-Process -FilePath $Pmd -ArgumentList @(
    'syslog', 'live', '--format', 'text', '--label',
    '--subsystem', 'com.otlobli.app', '--subsystem', 'com.apple.WebKit*',
    '--subsystem', 'com.apple.runningboard*', '--udid', $Udid
) -PassThru -WindowStyle Hidden -RedirectStandardOutput $UnifiedPath -RedirectStandardError $syslogError

$cdpBridgeProcess = Start-Process -FilePath $Pmd -ArgumentList @(
    'webinspector', 'cdp', '--host', '127.0.0.1', '--port', '9222', '--udid', $Udid
) -PassThru -WindowStyle Hidden -RedirectStandardOutput $cdpBridgeOut -RedirectStandardError $cdpBridgeError

$nodeArguments = @(
    (Join-Path $RepositoryRoot 'scripts\capture-shein-cdp-network.mjs'),
    '--endpoint=http://127.0.0.1:9222',
    "--mode=$Mode",
    "--run-id=$RunId",
    "--container=$ContainerIdentifier",
    "--output=$CdpPath",
    "--stop-file=$StopFile"
)
$cdpRecorderProcess = Start-Process -FilePath 'node' -ArgumentList $nodeArguments -WorkingDirectory $RepositoryRoot `
    -PassThru -WindowStyle Hidden -RedirectStandardError $cdpRecorderError

$pollJob = Start-Job -ScriptBlock {
    param($Tool, $TargetUdid, $OutputPath, $StopPath)
    while (-not (Test-Path -LiteralPath $StopPath)) {
        $at = [DateTimeOffset]::UtcNow.ToString('o')
        try {
            $raw = (& $Tool processes ps --udid $TargetUdid 2>$null | Out-String)
            $all = $raw | ConvertFrom-Json -AsHashtable
            $matches = @()
            foreach ($entry in $all.GetEnumerator()) {
                $name = [string]$entry.Value.ProcessName
                if ($name -eq 'App' -or $name -like '*WebContent*' -or $name -like '*Networking*' -or $name -like '*GPU*') {
                    $matches += [ordered]@{ pid = [int]$entry.Key; processName = $name }
                }
            }
            $pidRaw = (& $Tool developer dvt process-id-for-bundle-id com.otlobli.app --userspace --udid $TargetUdid 2>$null | Out-String)
            $pidMatches = [regex]::Matches($pidRaw, '(?m)^\s*(\d+)\s*$')
            $exactAppPid = if ($pidMatches.Count) { [int]$pidMatches[$pidMatches.Count - 1].Groups[1].Value } else { 0 }
            $record = [ordered]@{
                at = $at
                source = 'process-poll'
                appPid = $exactAppPid
                candidateAppPids = @($matches | Where-Object processName -eq 'App' | ForEach-Object pid)
                webContentPids = @($matches | Where-Object processName -like '*WebContent*' | ForEach-Object pid)
                relevantProcesses = $matches
            }
        } catch {
            $record = [ordered]@{ at = $at; source = 'process-poll'; error = $_.Exception.Message }
        }
        $record | ConvertTo-Json -Depth 8 -Compress | Add-Content -LiteralPath $OutputPath -Encoding utf8
        Start-Sleep -Milliseconds 600
    }
} -ArgumentList $Pmd, $Udid, $ProcessesPath, $StopFile

Start-Sleep -Seconds 2

$Outcome = 'UNKNOWN'
$FirstPid = 0
try {
    [void](Write-Marker 'CAPTURE_READY' '')
    $FirstPid = Write-Marker 'FIRST_OPEN' 'افتح تطبيق Otlobli واضغط SHEIN؛ يجب أن يفتح الوضع المحدد مباشرة بلا اختيار يدوي.'
    [void](Write-Marker 'WORKING_CONFIRMED' 'تأكد من عمل الصفحة، ثم افتح قسمًا ومنتجًا واحدًا على الأقل.' )

    switch ($Scenario) {
        'A1' {
            [void](Write-Marker 'LEAVE_STORE' 'أغلق متصفح SHEIN بزر Close للعودة إلى شاشة المتاجر، من دون إغلاق التطبيق.' )
            $secondPid = Write-Marker 'SECOND_OPEN' 'ادخل SHEIN مرة ثانية من شاشة المتاجر.'
            if ($FirstPid -gt 0 -and $secondPid -gt 0 -and $FirstPid -ne $secondPid) {
                Add-JsonLine $ControllerEvents ([ordered]@{ at = [DateTimeOffset]::UtcNow.ToString('o'); event = 'unexpected-app-pid-change'; firstPid = $FirstPid; secondPid = $secondPid })
            }
            $Outcome = Read-OutcomeMarker
        }
        'A2' {
            [void](Write-Marker 'APP_BACKGROUND' 'اذهب إلى شاشة Home فقط، ولا تقتل Otlobli من App Switcher.' )
            $foregroundPid = Write-Marker 'APP_FOREGROUND' 'ارجع إلى Otlobli وافتح القسم أو المنتج نفسه.'
            if ($FirstPid -gt 0 -and $foregroundPid -gt 0 -and $FirstPid -ne $foregroundPid) {
                Add-JsonLine $ControllerEvents ([ordered]@{ at = [DateTimeOffset]::UtcNow.ToString('o'); event = 'unexpected-app-pid-change'; firstPid = $FirstPid; foregroundPid = $foregroundPid })
            }
            $Outcome = Read-OutcomeMarker
        }
        { $_ -in @('A3', 'A4') } {
            [void](Write-Marker 'APP_KILLED' 'اقتل Otlobli من App Switcher الآن.' )
            [void](Assert-AppStopped $FirstPid)
            $secondPid = Write-Marker 'SECOND_OPEN' 'شغّل Otlobli تشغيلًا باردًا، ثم ادخل SHEIN؛ سيُعاد استخدام حاوية السيناريو نفسها.'
            if ($FirstPid -gt 0 -and $secondPid -eq $FirstPid) {
                throw "Cold launch reused the old app PID $FirstPid; the scenario is invalid."
            }
            $Outcome = Read-OutcomeMarker
        }
        default {
            if ($Scenario -in @('B1', 'B3')) {
                [void](Write-Marker 'CAPTURE_TESTED' 'افتح منتجين، اختر اللون والمقاس، واستعمل Add to Otlobli مرة واحدة.' )
            } elseif ($Scenario -eq 'B2') {
                [void](Write-Marker 'BLOCKING_TESTED' 'افتح منتجين وتأكد أن زر شراء SHEIN المحظور فقط غير ظاهر وأن بقية الصفحة تتفاعل.' )
            } else {
                [void](Write-Marker 'PRODUCTS_TESTED' 'اختبر قسمًا واحدًا ومنتجين اثنين.' )
            }
            $Outcome = Read-OutcomeMarker
        }
    }
    [void](Write-Marker 'BROWSER_CLOSED_FOR_EVIDENCE' 'أغلق متصفح SHEIN بزر Close فقط، واترك Otlobli مفتوحًا على شاشة المتاجر.' )
    [void](Write-Marker 'TEST_COMPLETE' '')
} finally {
    New-Item -ItemType File -Path $StopFile -Force | Out-Null
    if ($null -ne $cdpRecorderProcess) {
        try { $cdpRecorderProcess.WaitForExit(8000) | Out-Null } catch {}
    }
    Stop-CaptureProcess $cdpRecorderProcess 'cdp-recorder'
    Stop-CaptureProcess $cdpBridgeProcess 'cdp-bridge'
    Stop-CaptureProcess $syslogProcess 'unified-log'
    if ($null -ne $pollJob) {
        Wait-Job -Job $pollJob -Timeout 5 | Out-Null
        Stop-Job -Job $pollJob -ErrorAction SilentlyContinue
        Remove-Job -Job $pollJob -Force -ErrorAction SilentlyContinue
    }
}

Write-Phase 'PRESERVE READ-ONLY EVIDENCE'
try {
    & $Pmd apps pull $BundleId "shein-final-forensics-$RunId.jsonl" $RuntimePath --documents --udid $Udid 2>$null | Out-Null
} catch {
    Add-JsonLine $ControllerEvents ([ordered]@{ at = [DateTimeOffset]::UtcNow.ToString('o'); event = 'runtime-pull-failed'; error = $_.Exception.Message })
}

try {
    $remoteCache = "Library/WebKit/WebsiteDataStore/$ContainerIdentifier/NetworkCache"
    & $Pmd apps pull $BundleId $remoteCache $CacheDirectory --udid $Udid 2>$null | Out-Null
} catch {
    Add-JsonLine $ControllerEvents ([ordered]@{ at = [DateTimeOffset]::UtcNow.ToString('o'); event = 'network-cache-pull-failed'; error = $_.Exception.Message })
}

try {
    & $Pmd apps rm $BundleId $ScenarioFileName --documents --udid $Udid 2>$null | Out-Null
} catch {
    Add-JsonLine $ControllerEvents ([ordered]@{ at = [DateTimeOffset]::UtcNow.ToString('o'); event = 'scenario-config-cleanup-failed'; error = $_.Exception.Message })
}

$manifest.completedAt = [DateTimeOffset]::UtcNow.ToString('o')
$manifest.outcome = $Outcome
$manifest.evidenceDirectory = $EvidenceDirectory
Write-JsonFile $ManifestPath $manifest

Write-Phase 'DECODE AND ANALYZE'
$decodedUnified = Join-Path $EvidenceDirectory 'unified-decoded.jsonl'
$decodedUnifiedError = Join-Path $EvidenceDirectory 'unified-decode.stderr.log'
if ((Test-Path -LiteralPath $UnifiedPath) -and (Get-Item -LiteralPath $UnifiedPath).Length -gt 0) {
    try {
        & node (Join-Path $RepositoryRoot 'scripts\decode-shein-clean-room-log.mjs') $UnifiedPath 2>>$decodedUnifiedError |
            Set-Content -LiteralPath $decodedUnified -Encoding utf8
    } catch {
        Add-JsonLine $ControllerEvents ([ordered]@{ at = [DateTimeOffset]::UtcNow.ToString('o'); event = 'unified-decode-failed'; error = $_.Exception.Message })
    }
}

if (-not (Test-Path -LiteralPath $RuntimePath) -and (Test-Path -LiteralPath $decodedUnified)) {
    Copy-Item -LiteralPath $decodedUnified -Destination $RuntimePath
}
if (-not (Test-Path -LiteralPath $RuntimePath)) {
    New-Item -ItemType File -Path $RuntimePath | Out-Null
}
if (-not (Test-Path -LiteralPath $CdpPath)) {
    New-Item -ItemType File -Path $CdpPath | Out-Null
}

$networkAnalysis = Join-Path $EvidenceDirectory 'network-analysis.json'
& node (Join-Path $RepositoryRoot 'scripts\analyze-shein-cdp-network.mjs') $CdpPath "--native=$RuntimePath" "--output=$networkAnalysis"

$networkCacheRoot = Get-ChildItem -LiteralPath $CacheDirectory -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object Name -eq 'NetworkCache' | Select-Object -First 1 -ExpandProperty FullName
if (-not $networkCacheRoot -and (Test-Path -LiteralPath (Join-Path $CacheDirectory 'Version 17'))) {
    $networkCacheRoot = $CacheDirectory
}
$cacheAnalysis = Join-Path $EvidenceDirectory 'cache-analysis.json'
if ($networkCacheRoot) {
    & node (Join-Path $RepositoryRoot 'scripts\inspect-shein-webkit-cache.mjs') $networkCacheRoot "--output=$cacheAnalysis"
}

$analysisPath = Join-Path $EvidenceDirectory 'analysis.json'
$reportPath = Join-Path $EvidenceDirectory 'report.md'
$analysisArguments = @(
    (Join-Path $RepositoryRoot 'scripts\analyze-shein-final-forensics.mjs'),
    "--manifest=$ManifestPath",
    "--markers=$MarkersPath",
    "--runtime=$RuntimePath",
    "--processes=$ProcessesPath",
    "--network=$networkAnalysis",
    "--output=$analysisPath",
    "--report=$reportPath"
)
if (Test-Path -LiteralPath $cacheAnalysis) { $analysisArguments += "--cache=$cacheAnalysis" }
& node @analysisArguments

$hashFile = Join-Path $EvidenceDirectory 'SHA256SUMS.txt'
$hashLines = Get-ChildItem -LiteralPath $EvidenceDirectory -File -Recurse |
    Where-Object FullName -ne $hashFile |
    Sort-Object FullName |
    ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($EvidenceDirectory, $_.FullName).Replace('\', '/')
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
        "$hash  $relative"
    }
$hashLines | Set-Content -LiteralPath $hashFile -Encoding ascii

Write-Phase 'COMPLETE'
$analysis = Get-Content -LiteralPath $analysisPath -Raw | ConvertFrom-Json
Write-Host "Scenario: $Scenario / $Mode"
Write-Host "Container: $ContainerIdentifier"
Write-Host "Classification: $($analysis.classification)"
Write-Host "Evidence: $EvidenceDirectory"
