# EWItool

EWItool is an open source controller and patch editor/librarian for the popular Akai EWI4000s wind synthesizer.

EWItool includes a fully graphical sound (patch) editor and patch library management. From version 0.4 onwards there has been access to an online patch exchange (EPX) for sharing patches with others. For more information see our [wiki](https://github.com/SMerrony/EWItool/wiki).

EWItool has been developed by Steve Merrony. It has been redeveloped in Java (JavaFX) based on lessons learnt from the original C++/Qt version.

**EWItool runs on macOS (including Sonoma), Windows, and GNU/Linux.**

The latest version may always be downloaded from here: https://github.com/SMerrony/EWItool/releases

---

## Requirements

- **Java Runtime Environment (JRE) 11 or later** — JavaFX is no longer bundled with the JDK since Java 11, but the EWItool JAR bundles OpenJFX 21 (LTS) for all supported platforms (Linux x86-64, macOS Intel/Apple Silicon, Windows x86-64), so **no separate JavaFX installation is required**.
  - Any standard JRE/JDK 11+ works, including [Eclipse Temurin](https://adoptium.net/), [Oracle JDK](https://www.oracle.com/java/technologies/downloads/), [Amazon Corretto](https://aws.amazon.com/corretto/), and [Azul Zulu](https://www.azul.com/downloads/).
  - Java 22 (`java version "22.0.1"`) is fully supported.

## Running the pre-built JAR

Download `EWItool.jar` from the [releases page](https://github.com/SMerrony/EWItool/releases) and run:

```bash
java -jar EWItool.jar
```

On macOS you may also double-click the JAR file if `.jar` files are associated with Java.

---

## Troubleshooting — if the JAR does not open

If `java -jar EWItool.jar` does nothing, shows an error, or closes immediately, run the
appropriate diagnostic script below.  It collects system information (Java version, OS,
architecture, MIDI devices, display settings, and the error output from the JAR) and saves
everything to a file called `ewi-diagnostics.txt`.  Upload that file when reporting a bug.

### Linux / macOS

```bash
# Download the script alongside EWItool.jar, then:
chmod +x diagnose.sh
./diagnose.sh              # looks for EWItool.jar in the current directory
# or
./diagnose.sh /path/to/EWItool.jar
```

### Windows (PowerShell)

```powershell
# In a PowerShell window in the folder containing EWItool.jar:
.\diagnose.ps1
# or, if your execution policy blocks unsigned scripts, run first:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
.\diagnose.ps1 -JarPath "C:\path\to\EWItool.jar"
```

### Windows (double-click)

Double-click **`diagnose.bat`** in the same folder as `EWItool.jar`.  It runs
`diagnose.ps1` automatically and saves `ewi-diagnostics.txt` in the same folder.

### What the scripts check

| # | Check |
|---|-------|
| 1 | Operating system name, version, and CPU architecture |
| 2 | Java installation (version, vendor, path, registry entries) |
| 3 | Full Java system properties (`-XshowSettings:all`) |
| 4 | JAR file validity (magic bytes, size, manifest `Main-Class`) |
| 5 | Display / graphics environment (GPU, DPI, X11/Wayland) |
| 6 | MIDI / audio devices |
| 7 | Attempt to launch `EWItool.jar` and capture any error output |
| 8 | Environment variables (`PATH`, `JAVA_HOME`, etc.) |
| 9 | Available disk space |

> **Note:** The bundled OpenJFX native libraries cover **Linux x86-64, macOS Intel,
> macOS Apple Silicon, and Windows x86-64**.  Other architectures (e.g. Linux ARM /
> Raspberry Pi, 32-bit Windows) are not supported by the pre-built JAR.

---

## Building from source

### Prerequisites

- **JDK 11 or later** (e.g. [Eclipse Temurin 21](https://adoptium.net/) or [Oracle JDK 22](https://www.oracle.com/java/technologies/downloads/)) — OpenJFX is fetched automatically by Maven.
- **Apache Maven 3.6+**

### Build steps

```bash
# Clone the repository
git clone https://github.com/annaseedart/EWItool.git
cd EWItool

# Build the standalone fat JAR (OpenJFX is downloaded automatically)
mvn package
```

The resulting standalone JAR will be at `target/EWItool.jar`.

Run it with:

```bash
java -jar target/EWItool.jar
```

### Building a native standalone executable (Linux only)

Use the `standalone` Maven profile to produce a self-contained Linux app-image that bundles its own JRE.  The resulting `EWItool` binary can be run directly — no Java installation needed on the target machine.

> **Linux only** — `jpackage --type app-image` produces a `bin/EWItool` launcher on
> Linux.  On macOS the same command produces a `.app` bundle instead
> (see [Building a click-to-open macOS installer (.dmg)](#building-a-click-to-open-macos-installer-dmg) below).

> **Requires JDK 14 or later** (for `jpackage`).

```bash
mvn package -P standalone
```

The app-image is placed in `target/EWItool/`.  Run it with:

```bash
./target/EWItool/bin/EWItool
```

You can copy or move the entire `target/EWItool/` directory anywhere on your system.

> **macOS note:** If you run `mvn package -P standalone` on macOS, `jpackage` will
> produce `target/EWItool.app/` (a macOS app bundle) rather than
> `target/EWItool/bin/EWItool`.  The `standalone` profile is intended for Linux.
> For a macOS installer use the `macos-dmg` profile described in the next section.

### Building a click-to-open macOS installer (`.dmg`)

Use the `macos-dmg` Maven profile to produce a native macOS disk-image installer.
**This must be run on a macOS machine** — `jpackage` does not support cross-platform builds.

> **Requires JDK 14 or later** on macOS (for `jpackage`).

```bash
# Clone and build on macOS:
git clone https://github.com/annaseedart/EWItool.git
cd EWItool
mvn package -P macos-dmg
```

The resulting installer is at `target/EWItool-2.1.dmg`.

**Install and run:**
1. Double-click `EWItool-2.1.dmg` to mount the disk image.
2. Drag `EWItool.app` from the disk image into your **Applications** folder.
3. Eject the disk image.
4. Double-click `EWItool.app` in Applications to launch.

> **Gatekeeper note (macOS with Gatekeeper enabled):** Because the app is not
> signed with an Apple Developer certificate, macOS Gatekeeper may show
> *"EWItool cannot be opened because it is from an unidentified developer."*
> To bypass this **once**: right-click (or Control-click) `EWItool.app` →
> **Open** → click **Open** in the confirmation dialog.  After that first
> launch the app opens normally.
>
> Alternatively, go to **System Settings → Privacy & Security** and click
> **Open Anyway** next to the EWItool warning.

The `.app` bundle contains its own JRE for the host architecture (Intel x86_64 or
Apple Silicon AArch64 depending on which Mac you build on).  No separate Java
installation is required on the Mac that runs the app.

---

## Project structure

```
EWItool/
├── src/
│   └── main/
│       ├── java/ewitool/       # Java source files
│       └── resources/
│           ├── ewitool/        # CSS stylesheet
│           └── resources/      # Application icon (PNG)
├── diagnose.sh                 # Diagnostic script (Linux / macOS)
├── diagnose.ps1                # Diagnostic script (Windows PowerShell)
├── diagnose.bat                # Diagnostic launcher (Windows, double-click)
├── pom.xml                     # Maven build file
└── README.md
```

### Maven build profiles

| Profile | Platform | Command | Output |
|---|---|---|---|
| _(default)_ | any | `mvn package` | `target/EWItool.jar` — fat JAR, needs JRE 11+ to run |
| `standalone` | Linux | `mvn package -P standalone` | `target/EWItool/bin/EWItool` — native Linux launcher with bundled JRE |
| `macos-dmg` | **macOS** | `mvn package -P macos-dmg` | `target/EWItool-2.1.dmg` — click-to-open macOS disk-image installer |

---

## Licence

EWItool is released under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
Copyright © 2018 S. Merrony
