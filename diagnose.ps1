# ============================================================
# EWItool Diagnostic Script  (Windows – PowerShell)
# ============================================================
# Run this script on the computer where EWItool fails to open
# and send the resulting  ewi-diagnostics.txt  file to the
# project maintainer so they can investigate.
#
# Usage (in PowerShell):
#   .\diagnose.ps1
#   .\diagnose.ps1 -JarPath "C:\path\to\EWItool.jar"
#
# If you get an execution-policy error, run this first:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# ============================================================

param(
    [string]$JarPath = "EWItool.jar"
)

$OutputFile    = "ewi-diagnostics.txt"
$LaunchTimeout = 15   # seconds

# ── helpers ──────────────────────────────────────────────────
function Write-HR   { Write-Output "----------------------------------------" }
function Write-Section($title) {
    Write-Output ""
    Write-HR
    Write-Output "  $title"
    Write-HR
}
function Invoke-Safe([scriptblock]$block) {
    try { & $block } catch { "ERROR: $_" }
}

# ── capture all output to file AND console ───────────────────
# Transcript saves everything printed to the console into a file.
if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }
Start-Transcript -Path $OutputFile -NoClobber | Out-Null

Write-Output "EWItool Diagnostic Report"
Write-Output "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
Write-Output "Script version: 1.0"

# ── 1. Operating System ───────────────────────────────────────
Write-Section "1. Operating System"
Invoke-Safe {
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Output "Caption      : $($os.Caption)"
    Write-Output "Version      : $($os.Version)"
    Write-Output "BuildNumber  : $($os.BuildNumber)"
    Write-Output "Architecture : $($os.OSArchitecture)"
    Write-Output "SystemDrive  : $($os.SystemDrive)"
    Write-Output ""
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Output "Manufacturer : $($cs.Manufacturer)"
    Write-Output "Model        : $($cs.Model)"
    Write-Output "SystemType   : $($cs.SystemType)"
    Write-Output "TotalPhysRAM : $([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB"
}

# ── 2. Java Runtime ───────────────────────────────────────────
Write-Section "2. Java Runtime"
$javaCmd = $null
$javaLocations = @()

# Try to find java on PATH
try {
    $javaCmd = (Get-Command java -ErrorAction Stop).Source
    $javaLocations += $javaCmd
    Write-Output "java on PATH : $javaCmd"
    Write-Output ""
    Write-Output "java -version:"
    & java -version 2>&1 | ForEach-Object { Write-Output "  $_" }
} catch {
    Write-Output "WARNING: 'java' is NOT on PATH."
    Write-Output "Install Java 11+ from https://adoptium.net/ and ensure it is on PATH."
}

Write-Output ""
Write-Output "JAVA_HOME    : $(if ($env:JAVA_HOME) { $env:JAVA_HOME } else { '<not set>' })"

# Search common install locations
Write-Output ""
Write-Output "Searching common Java install paths..."
$searchRoots = @(
    "$env:ProgramFiles\Java",
    "$env:ProgramFiles\Eclipse Adoptium",
    "$env:ProgramFiles\Microsoft",
    "$env:ProgramFiles\BellSoft",
    "$env:ProgramFiles\Azul Systems",
    "${env:ProgramFiles(x86)}\Java",
    "$env:LOCALAPPDATA\Programs\Eclipse Adoptium"
)
foreach ($root in $searchRoots) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Filter "java.exe" -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Output "  Found: $($_.FullName)" }
    }
}

# Also check registry
Write-Output ""
Write-Output "Java registry entries:"
$regPaths = @(
    "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment",
    "HKLM:\SOFTWARE\JavaSoft\Java Development Kit",
    "HKLM:\SOFTWARE\JavaSoft\JRE",
    "HKLM:\SOFTWARE\JavaSoft\JDK",
    "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Runtime Environment",
    "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Development Kit"
)
foreach ($reg in $regPaths) {
    if (Test-Path $reg) {
        Write-Output "  $reg"
        Get-ChildItem $reg -ErrorAction SilentlyContinue |
            ForEach-Object {
                $ver = $_.PSChildName
                $home = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).JavaHome
                Write-Output "    Version $ver => $home"
            }
    }
}

# ── 3. Java system properties ────────────────────────────────
Write-Section "3. Java System Properties"
if ($javaCmd) {
    Invoke-Safe {
        & java -XshowSettings:all -version 2>&1 | Select-Object -First 80 |
            ForEach-Object { Write-Output "  $_" }
    }
} else {
    Write-Output "Skipped (java not available)."
}

# ── 4. EWItool JAR file ───────────────────────────────────────
Write-Section "4. EWItool JAR file"
if (Test-Path $JarPath) {
    $jar = Get-Item $JarPath
    Write-Output "Path     : $($jar.FullName)"
    Write-Output "Size     : $($jar.Length) bytes"
    Write-Output "LastWrite: $($jar.LastWriteTime)"

    # Validate ZIP magic bytes (PK\x03\x04)
    $bytes = [System.IO.File]::ReadAllBytes($jar.FullName)
    $magic = '{0:X2}{1:X2}{2:X2}{3:X2}' -f $bytes[0],$bytes[1],$bytes[2],$bytes[3]
    Write-Output "Magic    : $magic"
    if ($magic -eq "504B0304") {
        Write-Output "Format   : valid ZIP/JAR"
    } else {
        Write-Output "Format   : INVALID — not a ZIP/JAR file (expected 504B0304)"
    }

    # Print manifest
    Write-Output ""
    Write-Output "JAR manifest:"
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip  = [System.IO.Compression.ZipFile]::OpenRead($jar.FullName)
        $entry = $zip.Entries | Where-Object { $_.FullName -eq "META-INF/MANIFEST.MF" }
        if ($entry) {
            $reader = [System.IO.StreamReader]::new($entry.Open())
            Write-Output $reader.ReadToEnd()
            $reader.Close()
        } else {
            Write-Output "  (MANIFEST.MF not found in JAR)"
        }
        $zip.Dispose()
    } catch {
        Write-Output "  (could not read manifest: $_)"
    }
} else {
    Write-Output "ERROR: JAR not found at '$JarPath'"
    Write-Output "Specify the correct path: .\diagnose.ps1 -JarPath 'C:\path\to\EWItool.jar'"
}

# ── 5. Display / Graphics ────────────────────────────────────
Write-Section "5. Display / Graphics"
Invoke-Safe {
    $displays = Get-CimInstance Win32_VideoController
    foreach ($d in $displays) {
        Write-Output "Name            : $($d.Name)"
        Write-Output "DriverVersion   : $($d.DriverVersion)"
        Write-Output "VideoModeDesc   : $($d.VideoModeDescription)"
        Write-Output "CurrentHRes     : $($d.CurrentHorizontalResolution)"
        Write-Output "CurrentVRes     : $($d.CurrentVerticalResolution)"
        Write-Output "AdapterRAM      : $([math]::Round($d.AdapterRAM / 1MB, 0)) MB"
        Write-Output ""
    }
}
Write-Output "DPI scaling (registry):"
Invoke-Safe {
    $dpi = (Get-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" -ErrorAction SilentlyContinue).AppliedDPI
    if ($dpi) { Write-Output "  AppliedDPI = $dpi" } else { Write-Output "  (not set)" }
}

# ── 6. MIDI ──────────────────────────────────────────────────
Write-Section "6. MIDI devices"
Invoke-Safe {
    $midi = Get-CimInstance Win32_SoundDevice
    if ($midi) {
        foreach ($d in $midi) {
            Write-Output "Name     : $($d.Name)"
            Write-Output "Status   : $($d.Status)"
            Write-Output "DeviceID : $($d.DeviceID)"
            Write-Output ""
        }
    } else {
        Write-Output "(no sound devices found via WMI)"
    }
}

# ── 7. Attempt to launch EWItool ─────────────────────────────
Write-Section "7. EWItool launch attempt (${LaunchTimeout}s timeout)"
if ($javaCmd -and (Test-Path $JarPath)) {
    Write-Output "Running: java -jar `"$JarPath`""
    Write-Output "(The application window may appear briefly — this is expected.)"
    Write-Output ""

    $jarFullPath = (Get-Item $JarPath).FullName
    $proc = $null
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName               = $javaCmd
        $psi.Arguments              = "-jar `"$jarFullPath`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute        = $false
        $psi.CreateNoWindow         = $false

        $proc = [System.Diagnostics.Process]::Start($psi)
        $finished = $proc.WaitForExit($LaunchTimeout * 1000)

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()

        if ($finished) {
            Write-Output "Exit code: $($proc.ExitCode)"
        } else {
            $proc.Kill()
            Write-Output "Exit code: (timed out after ${LaunchTimeout}s — the app may have launched successfully)"
        }

        Write-Output ""
        Write-Output "--- stdout ---"
        if ($stdout) { Write-Output $stdout } else { Write-Output "(empty)" }
        Write-Output "--- stderr ---"
        if ($stderr) { Write-Output $stderr } else { Write-Output "(empty)" }
        Write-Output "--- end output ---"
    } catch {
        Write-Output "Launch failed with exception: $_"
    } finally {
        if ($proc -and -not $proc.HasExited) { try { $proc.Kill() } catch {} }
    }
} else {
    Write-Output "Skipped (java or JAR not available — see sections 2 and 4 above)."
}

# ── 8. Environment summary ────────────────────────────────────
Write-Section "8. Environment summary"
Write-Output "PATH      : $env:PATH"
Write-Output "USERPROFILE: $env:USERPROFILE"
Write-Output "USERNAME  : $env:USERNAME"
Write-Output "COMPUTERNAME: $env:COMPUTERNAME"

# ── 9. Disk space ─────────────────────────────────────────────
Write-Section "9. Disk space"
Invoke-Safe {
    Get-PSDrive -PSProvider FileSystem | Select-Object Name,
        @{N='Used(GB)';E={[math]::Round($_.Used/1GB,2)}},
        @{N='Free(GB)';E={[math]::Round($_.Free/1GB,2)}} |
        Format-Table -AutoSize | Out-String | Write-Output
}

# ── Done ──────────────────────────────────────────────────────
Write-Section "Done"
Write-Output "Diagnostic report saved to: $OutputFile"
Write-Output ""
Write-Output "Please upload '$OutputFile' so the maintainer can investigate."
Write-Output "The file is in the directory where you ran this script:"
Write-Output "  $((Get-Location).Path)\$OutputFile"

Stop-Transcript | Out-Null
