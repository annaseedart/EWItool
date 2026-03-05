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

---

## Project structure

```
EWItool/
├── src/
│   └── main/
│       ├── java/ewitool/       # Java source files
│       └── resources/
│           ├── ewitool/        # CSS stylesheet
│           └── resources/      # Application icon
├── pom.xml                     # Maven build file
└── README.md
```

---

## Licence

EWItool is released under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
Copyright © 2018 S. Merrony
