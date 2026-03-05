#!/usr/bin/env bash
# ============================================================
# EWItool Diagnostic Script  (Linux / macOS)
# ============================================================
# Run this script on the computer where EWItool fails to open
# and send the resulting  ewi-diagnostics.txt  file to the
# project maintainer so they can investigate.
#
# Usage:
#   chmod +x diagnose.sh
#   ./diagnose.sh [/path/to/EWItool.jar]
#
# If no path is given the script looks for EWItool.jar in the
# current directory.
# ============================================================

set -euo pipefail

JAR_PATH="${1:-EWItool.jar}"
OUTPUT_FILE="ewi-diagnostics.txt"
LAUNCH_TIMEOUT=15   # seconds to let the JVM start before giving up

# ── helpers ──────────────────────────────────────────────────
hr() { printf '%s\n' "----------------------------------------"; }
section() { echo; hr; echo "  $1"; hr; }
cmd_or_na() {
    # Run a command and print its stdout+stderr; print "n/a" if unavailable
    if command -v "$1" >/dev/null 2>&1; then
        "$@" 2>&1 || true
    else
        echo "n/a (command '$1' not found)"
    fi
}

# ── redirect all output to file AND console ───────────────────
exec > >(tee -a "$OUTPUT_FILE") 2>&1
# Start fresh
> "$OUTPUT_FILE"

echo "EWItool Diagnostic Report"
echo "Generated: $(date)"
echo "Script version: 1.0"

# ── 1. Operating System ───────────────────────────────────────
section "1. Operating System"
echo "uname -a : $(uname -a)"
echo "OS       : $(uname -s)"
echo "Kernel   : $(uname -r)"
echo "Machine  : $(uname -m)"

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macOS    : $(sw_vers -productVersion 2>/dev/null || echo n/a)"
    echo "Build    : $(sw_vers -buildVersion  2>/dev/null || echo n/a)"
elif [[ -f /etc/os-release ]]; then
    echo "--- /etc/os-release ---"
    cat /etc/os-release
fi

# ── 2. Java ───────────────────────────────────────────────────
section "2. Java Runtime"
if command -v java >/dev/null 2>&1; then
    java -version 2>&1
    echo "java binary : $(command -v java)"
    # Resolve symlinks to find the real binary
    REAL_JAVA="$(readlink -f "$(command -v java)" 2>/dev/null || \
                 realpath   "$(command -v java)" 2>/dev/null || \
                 echo n/a)"
    echo "real path   : $REAL_JAVA"
else
    echo "ERROR: 'java' is NOT on PATH."
    echo "Install Java 11+ (e.g. https://adoptium.net/) and ensure it is on PATH."
fi

echo ""
echo "JAVA_HOME : ${JAVA_HOME:-<not set>}"

# List other java binaries that might exist
echo ""
echo "Other java installations found by 'which -a' / locate:"
cmd_or_na which -a java

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo ""
    echo "macOS /usr/libexec/java_home output:"
    /usr/libexec/java_home -V 2>&1 || true
fi

# ── 3. Java system properties (if java is available) ─────────
section "3. Java System Properties"
if command -v java >/dev/null 2>&1; then
    java -XshowSettings:all -version 2>&1 | head -80 || true
fi

# ── 4. EWItool JAR file ───────────────────────────────────────
section "4. EWItool JAR file"
if [[ -f "$JAR_PATH" ]]; then
    echo "Path     : $JAR_PATH"
    echo "Size     : $(wc -c < "$JAR_PATH") bytes"
    echo "Perms    : $(ls -l "$JAR_PATH")"
    # Verify it is a valid ZIP/JAR (starts with PK magic bytes)
    MAGIC="$(od -A n -t x1 -N 4 "$JAR_PATH" 2>/dev/null | tr -d ' ')"
    echo "Magic    : $MAGIC"
    if [[ "$MAGIC" == "504b0304" ]]; then
        echo "Format   : valid ZIP/JAR"
    else
        echo "Format   : INVALID — not a ZIP/JAR file (expected 504b0304)"
    fi
    # Print the manifest main class
    echo ""
    echo "JAR manifest:"
    if command -v unzip >/dev/null 2>&1; then
        unzip -p "$JAR_PATH" META-INF/MANIFEST.MF 2>/dev/null || echo "  (could not read manifest)"
    elif command -v jar >/dev/null 2>&1; then
        jar xf "$JAR_PATH" META-INF/MANIFEST.MF 2>/dev/null && cat META-INF/MANIFEST.MF && rm -rf META-INF
    else
        echo "  (neither 'unzip' nor 'jar' available to read manifest)"
    fi
else
    echo "ERROR: JAR not found at '$JAR_PATH'"
    echo "Specify the correct path: ./diagnose.sh /full/path/to/EWItool.jar"
fi

# ── 5. Display / Graphics ────────────────────────────────────
section "5. Display / Graphics environment"
echo "DISPLAY       : ${DISPLAY:-<not set>}"
echo "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-<not set>}"
echo "XDG_SESSION_TYPE: ${XDG_SESSION_TYPE:-<not set>}"

if [[ "$(uname -s)" == "Linux" ]]; then
    echo ""
    echo "xrandr output:"
    cmd_or_na xrandr --query

    echo ""
    echo "Checking for libGL / OpenGL:"
    ldconfig -p 2>/dev/null | grep -i 'libGL\|libEGL\|libX11\|libXext' | head -20 || true
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "system_profiler (display):"
    system_profiler SPDisplaysDataType 2>/dev/null | head -40 || true
fi

# ── 6. MIDI ──────────────────────────────────────────────────
section "6. MIDI subsystem"
if [[ "$(uname -s)" == "Linux" ]]; then
    echo "ALSA version:"
    cmd_or_na cat /proc/asound/version
    echo ""
    echo "ALSA devices:"
    cmd_or_na aplay -l
    echo ""
    echo "ALSA MIDI seq devices:"
    cmd_or_na aconnect -l
    echo ""
    echo "USB audio devices (lsusb):"
    cmd_or_na lsusb | grep -i 'audio\|midi\|akai\|ewi' || echo "  (none matching audio/midi/akai/ewi)"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "CoreAudio MIDI devices:"
    system_profiler SPAudioDataType 2>/dev/null | head -60 || true
fi

# ── 7. Attempt to launch EWItool (capture output) ────────────
section "7. EWItool launch attempt (${LAUNCH_TIMEOUT}s timeout)"
if command -v java >/dev/null 2>&1 && [[ -f "$JAR_PATH" ]]; then
    echo "Running: java -jar \"$JAR_PATH\""
    echo "(The application window may appear briefly — this is expected.)"
    echo ""
    # Run with a timeout; capture stderr; suppress graphical window noise
    # We set DISPLAY to :0 only if the normal display is absent (headless fallback)
    LAUNCH_ENV=""
    if [[ "$(uname -s)" == "Linux" ]] && [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        LAUNCH_ENV="DISPLAY=:0"
        echo "(No DISPLAY set; trying DISPLAY=:0)"
    fi

    LAUNCH_OUTPUT=""
    set +e
    LAUNCH_OUTPUT=$(
        env $LAUNCH_ENV \
        timeout "$LAUNCH_TIMEOUT" \
        java -jar "$JAR_PATH" 2>&1
    )
    LAUNCH_EXIT=$?
    set -e

    echo "Exit code: $LAUNCH_EXIT"
    if [[ $LAUNCH_EXIT -eq 124 ]]; then
        echo "(Timed out after ${LAUNCH_TIMEOUT}s — this may mean the app launched successfully"
        echo " but a display/window is required to close it.)"
    fi
    echo ""
    echo "--- captured output ---"
    echo "$LAUNCH_OUTPUT"
    echo "--- end output ---"
else
    echo "Skipped (java or JAR not available — see sections 2 and 4 above)."
fi

# ── 8. Environment summary ────────────────────────────────────
section "8. Environment summary"
echo "PATH      : $PATH"
echo "HOME      : ${HOME:-<not set>}"
echo "USER      : ${USER:-<not set>}"
echo "LANG      : ${LANG:-<not set>}"
echo "LC_ALL    : ${LC_ALL:-<not set>}"

# ── 9. Disk space ─────────────────────────────────────────────
section "9. Disk space"
df -h . 2>/dev/null || df . 2>/dev/null || true

# ── Done ──────────────────────────────────────────────────────
section "Done"
echo "Diagnostic report saved to: $OUTPUT_FILE"
echo ""
echo "Please upload '$OUTPUT_FILE' so the maintainer can investigate."
echo "The file is in the directory where you ran this script:"
echo "  $(pwd)/$OUTPUT_FILE"
