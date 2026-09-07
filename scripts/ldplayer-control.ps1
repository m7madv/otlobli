# Terminal-only LDPlayer control. No account, browser, or tester automation.
[CmdletBinding()]
param(
    [ValidateSet('Status', 'Start', 'Stop', 'Diagnose')]
    [string]$Action = 'Status',
    [ValidateRange(1, 12)]
    [int[]]$Instance = @(),
    [string]$InstallPath = 'C:\LDPlayer\LDPlayer9',
    [string]$AdbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$consolePath = Join-Path $InstallPath 'ldconsole.exe'
if (!(Test-Path -LiteralPath $consolePath -PathType Leaf)) {
    throw "LDPlayer CLI not found: $consolePath"
}

function Invoke-ReadCommand {
    param([string]$File, [string[]]$NativeArguments)
    # All callers below supply fixed words or validated integers, never shell text.
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $File
    $info.Arguments = $NativeArguments -join ' '
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(8000)) {
            $process.Kill()
            throw 'Diagnostic command timed out; the emulator was not stopped.'
        }
        if ($process.ExitCode -ne 0) {
            # Do not print arbitrary guest output (could contain private content).
            throw "Diagnostic command failed with exit code $($process.ExitCode)."
        }
        return $stdout.GetAwaiter().GetResult()
    } finally {
        $process.Dispose()
    }
}

function Get-Instances {
    $raw = Invoke-ReadCommand $consolePath @('list2')
    foreach ($line in ($raw -split '\r?\n')) {
        # Title is intentionally omitted from output: labels contain email addresses.
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^(\d+),.*,(-?\d+),(-?\d+),(\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+),(-?\d+)$') {
            $index = [int]$Matches[1]
            $config = Get-Content -LiteralPath (Join-Path $InstallPath "vms\config\leidian$index.config") -Raw | ConvertFrom-Json
            [pscustomobject]@{
                Instance = $index + 1
                Index = $index
                Running = ([int]$Matches[4] -ne 0 -or [int]$Matches[5] -gt 0 -or [int]$Matches[6] -gt 0)
                ReportedState = [int]$Matches[4]
                PlayerPid = [int]$Matches[5]
                EnginePid = [int]$Matches[6]
                CPU = $config.'advancedSettings.cpuCount'
                MemoryMB = $config.'advancedSettings.memorySize'
                FPS = if ($config.PSObject.Properties['basicSettings.fps']) { $config.'basicSettings.fps' } else { $null }
                ADBEnabled = if ($config.PSObject.Properties['basicSettings.adbDebug']) { $config.'basicSettings.adbDebug' -ne 0 } else { $false }
            }
        } else {
            throw 'Unrecognized LDPlayer status format; stopped to avoid an unsafe instance count.'
        }
    }
}

function Invoke-GuestRead {
    param([string]$Serial, [string[]]$Command)
    Invoke-ReadCommand $AdbPath (@('-s', $Serial, 'shell') + $Command)
}

function Get-Diagnostics {
    param($Rows)
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $deviceRows = ''
    if (Test-Path -LiteralPath $AdbPath -PathType Leaf) {
        $deviceRows = Invoke-ReadCommand $AdbPath @('devices')
    }
    $guestReports = @(foreach ($row in $Rows) {
        $serial = 'emulator-' + (5554 + 2 * $row.Index)
        $report = [ordered]@{
            Instance = $row.Instance
            Running = $row.Running
            ConfiguredMemoryMB = $row.MemoryMB
            GuestDiagnostics = 'Unavailable: not running or ADB is not enabled. No setting was changed.'
        }
        if ($row.Running -and $deviceRows -match "(?m)^$serial\s+device\s*$") {
            try {
                $memory = Invoke-GuestRead $serial @('cat', '/proc/meminfo')
                $chrome = Invoke-GuestRead $serial @('dumpsys', 'package', 'com.android.chrome')
                $anr = Invoke-GuestRead $serial @('dumpsys', 'activity', 'lastanr')
                $report.GuestDiagnostics = 'Read-only ADB succeeded'
                $report.BootCompleted = (Invoke-GuestRead $serial @('getprop', 'sys.boot_completed')).Trim() -eq '1'
                $report.Memory = @($memory -split '\r?\n' | Where-Object { $_ -match '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' })
                $report.ChromeVersion = if ($chrome -match 'versionName=([^\s]+)') { $Matches[1] } else { 'Not installed' }
                $report.ANRRecordedSinceBoot = $anr -notmatch '<no ANR has occurred since boot>'
                # Never return ANR contents, accounts, browser URLs, or page text.
            } catch {
                $report.GuestDiagnostics = 'Read-only guest query failed or timed out.'
            }
        }
        [pscustomobject]$report
    })
    [pscustomobject]@{
        TimestampUTC = [DateTime]::UtcNow.ToString('o')
        HostRAMFreeMB = [math]::Round($os.FreePhysicalMemory / 1024)
        HostRAMTotalMB = [math]::Round($os.TotalVisibleMemorySize / 1024)
        HostCPULoadPercent = $cpu.LoadPercentage
        Guests = $guestReports
        BrowserInteractionVerified = $false
    }
}

$selected = @($Instance | Select-Object -Unique)
$allRows = @(Get-Instances)
foreach ($number in $selected) {
    if (!($allRows | Where-Object Instance -eq $number)) { throw "Instance $number does not exist." }
}
if ($Action -in @('Start', 'Stop') -and $selected.Count -eq 0) {
    throw 'Supply -Instance with explicit numbers from 1 to 12.'
}
if ($Action -eq 'Start') {
    $running = @($allRows | Where-Object Running)
    $toStart = @($allRows | Where-Object { $_.Instance -in $selected -and !$_.Running })
    if ($running.Count + $toStart.Count -gt 2) {
        throw 'Maximum two running instances. Stop a specified instance first; nothing was stopped automatically.'
    }
    $freeMB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
    $requiredMB = 2048 + ($toStart.Count * 4096)
    if ($toStart.Count -gt 0 -and $freeMB -lt $requiredMB) {
        throw "Insufficient memory headroom: $([int]$freeMB) MB free; $requiredMB MB required. No apps were closed."
    }
    foreach ($row in $toStart) {
        # Deliberately no -Wait: ldconsole launch stays attached to descendants.
        Start-Process -FilePath $consolePath -ArgumentList @('launch', '--index', [string]$row.Index) -WindowStyle Hidden | Out-Null
        $timer = [Diagnostics.Stopwatch]::StartNew()
        do {
            Start-Sleep -Seconds 3
            $fresh = @(Get-Instances) | Where-Object Instance -eq $row.Instance
        } while ((!$fresh -or !$fresh.Running) -and $timer.Elapsed.TotalSeconds -lt 45)
        if (!$fresh -or !$fresh.Running) { throw "Instance $($row.Instance) did not start; no other instance was launched." }
        Write-Host "Instance $($row.Instance) process started; Android/browser readiness is not yet verified."
        if ($row.Instance -ne $toStart[-1].Instance) { Start-Sleep -Seconds 15 }
    }
} elseif ($Action -eq 'Stop') {
    $ownedProcesses = @(foreach ($row in ($allRows | Where-Object { $_.Instance -in $selected -and $_.Running })) {
        foreach ($taskPid in @($row.PlayerPid, $row.EnginePid)) {
            if ($taskPid -gt 0) { Get-Process -Id $taskPid -ErrorAction SilentlyContinue }
        }
    })
    foreach ($row in ($allRows | Where-Object { $_.Instance -in $selected -and $_.Running })) {
        # Graceful CLI quit of explicitly selected instances only, never quitall.
        & $consolePath quit --index $row.Index | Out-Null
    }
    $shutdownTimer = [Diagnostics.Stopwatch]::StartNew()
    do {
        Start-Sleep -Seconds 2
        $pending = @($ownedProcesses | Where-Object { !$_.HasExited })
    } while ($pending.Count -gt 0 -and $shutdownTimer.Elapsed.TotalSeconds -lt 30)
    if ($pending.Count -gt 0) {
        throw 'Graceful shutdown is still pending. No process was force-killed; wait before launching another pair.'
    }
}
$rows = @(Get-Instances | Where-Object { $selected.Count -eq 0 -or $_.Instance -in $selected })
if ($Action -eq 'Diagnose') {
    Get-Diagnostics $rows | ConvertTo-Json -Depth 6
} else {
    ConvertTo-Json -InputObject $rows -Depth 4
}
