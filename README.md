# EWItool

EWItool is an open source controller and patch editor/librarian for the popular Akai EWI4000s wind synthesizer.

EWItool includes a fully graphical sound (patch) editor and patch library management. From version 0.4 onwards there has been access to an online patch exchange (EPX) for sharing patches with others. For more information see our [wiki](https://github.com/SMerrony/EWItool/wiki).

EWItool has been developed by Steve Merrony. It has been redeveloped in Java (JavaFX) based on lessons learnt from the original C++/Qt version.

**EWItool runs on macOS (including Sonoma), Windows, and GNU/Linux.**

The latest version may always be downloaded from here: https://github.com/SMerrony/EWItool/releases

---

## Requirements

- **Java Runtime Environment (JRE) 8** — JavaFX is bundled with Java 8, so no additional installation is needed.
  - On macOS Sonoma, use [Azul Zulu JDK 8](https://www.azul.com/downloads/?version=java-8-lts&os=macos&package=jdk-fx) (includes JavaFX) or [Oracle JDK 8](https://www.oracle.com/java/technologies/downloads/#java8-mac).

## Running the pre-built JAR

Download `EWItool.jar` from the [releases page](https://github.com/SMerrony/EWItool/releases) and run:

```bash
java -jar EWItool.jar
```

On macOS you may also double-click the JAR file if `.jar` files are associated with Java.

---

## Building from source

### Prerequisites

- **JDK 8** with bundled JavaFX (e.g. [Azul Zulu JDK 8 with JavaFX](https://www.azul.com/downloads/?version=java-8-lts&package=jdk-fx))
- **Apache Maven 3.6+**

### Build steps

```bash
# Clone the repository
git clone https://github.com/annaseedart/EWItool.git
cd EWItool

# Build the standalone JAR (requires JDK 8 as JAVA_HOME)
export JAVA_HOME=/path/to/jdk8   # adjust to your JDK 8 installation
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
