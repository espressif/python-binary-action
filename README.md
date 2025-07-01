[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/espressif/python-binary-action/master.svg)](https://results.pre-commit.ci/latest/github/espressif/python-binary-action/master)

# Python Binary Build Action

A GitHub Action for building Python applications into standalone executables using `PyInstaller` across multiple architectures and platforms.

## Overview

This action automates the process of creating standalone executables from Python applications using `PyInstaller`. It supports multiple target platforms including Windows, macOS, and Linux (both x86_64 and ARM architectures). The action handles platform-specific configurations, dependency installation, and binary verification automatically.

### Motivation

This action provides several key benefits:

**Centralized Build Logic**: Eliminates code duplication across repositories by providing a single, centrally maintained build solution. This ensures consistent build processes and easier maintenance.

**Reduced Antivirus False Positives**: Antivirus software often flags PyInstaller-generated executables as suspicious. By centrally controlling `PyInstaller` versions and configurations, this action helps minimize false positive reports through tested and optimized settings.

**User Accessibility**: Many users prefer standalone executables over Python scripts, as they eliminate the need to install Python and manage dependencies. This is particularly valuable for:

- Users unfamiliar with Python installation and package management
- Legacy systems with unsupported Python versions
- Deployment scenarios requiring minimal dependencies

## Supported Platforms

- **Windows**: `windows-amd64`
- **Linux**: `linux-amd64`, `linux-armv7`, `linux-aarch64`
- **macOS**: `macos-amd64`, `macos-arm64`

## Features

- **Multi-architecture support**: Builds for x86_64 and ARM architectures
- **Cross-platform compatibility**: Supports Windows, macOS, and Linux
- **Automatic dependency handling**: Installs Python dependencies and system packages
- **Flexible data file inclusion**: Supports per-script configuration with wildcard support
- **Executable verification**: Tests built executables to ensure they run correctly
- **Windows icon support**: Allows custom icons for Windows executables
- **Flexible `PyInstaller` configuration**: Supports additional `PyInstaller` arguments
- **ARM cross-compilation**: Uses Public Preview runners for aarch64 and Docker containers with Qemu for ARMv7 architecture builds
- **GLIBC 2.31+ support**: Uses older Linux images in Docker for best compatibility with Linux targets

## Usage Examples

For more detailed explanation of input variables and advanced use cases, please see the [Inputs](#inputs) section below.

### Basic Usage

```yaml
- name: Build Python executable
  uses: espressif/python-binary-action@master
  with:
    scripts: 'main.py'
    output-dir: './dist'
    target-platform: 'linux-amd64'
```

### Multi-File Build with Data Files

Sometimes your Python script might require additional non-Python files, like assets (images), JSON or YAML files. These can be included for either all scripts or you can define files per script.

For example with the following project structure:

```txt
my_script/
src/
├── assets/
|   └── image.svg
├── config/
|   └── config.json
├── app.py
├── main.py
├── icon.ico
├── pyproject.toml
└── README.md
```

There is a config file that is used in both `app.py` and `main.py`, but only `app.py` requires images. The action can look something like this:

```yaml
- name: Build multiple executables
  uses: espressif/python-binary-action@master
  with:
    # Mandatory args
    scripts: 'main.py app.py'
    output-dir: './binaries'
    target-platform: 'windows-amd64'
    # Optional args; non-python files to include
    include-data-dirs: |
      {
        "app.py": ["./assets"],
        "*": ["./config"]
      }
    icon-file: './icon.ico'  # Icon for Windows executable
```

There are two options how to define data files to be included for all scripts:

1. With wildcard `*`

```json
{
  "*": ["./config"]
}
```

2. Simple list

```json
["./config"]
```

Both options are equivalent, but the wildcard allows you to define additional data files that are specific for one script. As can be seen in the above example for `app.py`.

### Custom Executable Names

Sometimes it might be useful to have a control over the name of build binary (executable). For example if we have a following structure of the project:

```txt
my_script/
├── src/
│   ├── __init__.py
│   └── __main__.py
├── pyproject.toml
└── README.md
```

Building the project with default configuration will result in script name `__main__.py`, which is probably not desirable. To solve this issue, we can pass optional argument `script-name` that will be used as basename for build binaries (executables).

```yaml
- name: Build with custom names
  uses: espressif/python-binary-action@master
  with:
    scripts: 'src/__main__.py'
    script-name: 'my_script'
    output-dir: './dist'
    target-platform: 'linux-amd64'
```

### ARM Architecture Build

```yaml
- name: Build for ARMv7
  uses: espressif/python-binary-action@master
  with:
    scripts: 'main.py'
    output-dir: './arm-binaries'
    target-platform: 'linux-armv7'
    additional-arm-packages: 'openssl libffi-dev libffi7 libssl-dev'
    python-version: '3.11'
```

### Custom PyInstaller Configuration

```yaml
- name: Build with custom options
  uses: espressif/python-binary-action@master
  with:
    scripts: 'app.py'
    output-dir: './dist'
    target-platform: 'macos-arm64'
    additional-args: '--hidden-import=requests --hidden-import=urllib3 --strip'
    pyinstaller-version: '6.3.0'
    test-command-args: '--version'
```

### Complete Workflow

Here you can see a simplified version of workflow used in [esptool](https://github.com/espressif/esptool/) repository:

```yaml
name: Build Executables

on: [push, pull_request]

jobs:
  build:
    runs-on: ${{ matrix.runner }}
    strategy:
      fail-fast: false  # Avoid failure of all action in case of one of them fails
      # Define platform matrix to build on multiple platforms at the same time
      matrix:
        platform: [windows-amd64, linux-amd64, macos-arm64, linux-aarch64]
        include:
          - platform: windows-amd64
            runner: windows-latest
          - platform: linux-amd64
            runner: ubuntu-latest
          - platform: macos-arm64
            runner: macos-latest
          - platform: linux-aarch64
            runner: ubuntu-24.04-arm

    env:
      # Used for additional data to be included in executables
      # Env variable is only for action simplification
      STUBS_DIR: ./esptool/targets/stub_flasher/

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.13'

      - name: Build executable
        uses: espressif/python-binary-action@master
        with:
          # Required options
          scripts: 'esptool.py'  # Building from 'esptool.py' file
          output-dir: './${{ matrix.platform }}'
          target-platform: ${{ matrix.platform }}
          # Optional args; non-python files that will be added to build executable
          # We want to include the content of subdirectories `1` and `2` of the directory stored in environment variable `STUBS_DIR`.
          include-data-dirs: |
            {
              "esptool.py": [
                "${{ env.STUBS_DIR }}1",
                "${{ env.STUBS_DIR }}2",
              ]
            }

      - name: Add license and readme
        shell: bash
        run: cp LICENSE README.md ./${{ matrix.platform }}

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: executable-${{ matrix.platform }}
          path: ./${{ matrix.platform }}
```

## Inputs

### Required Inputs

| Input             | Description                                     | Example                    |
|-------------------|-------------------------------------------------|----------------------------|
| `scripts`         | Space-separated list of Python scripts to build | `"esptool.py espefuse.py"` |
| `output-dir`      | Output directory for built executables          | `"./dist-linux-amd64"`     |
| `target-platform` | Target platform for the build                   | `"linux-amd64"`            |

### Optional Inputs

| Input                     | Description                               | Default                                     | Example                                      |
|---------------------------|-------------------------------------------|---------------------------------------------|----------------------------------------------|
| `script-name`             | Custom names for the output executables. Must provide exactly one name per script in the same order. (On Windows `.exe` suffix will be added to each name) | `""` | `"foo bar"`         |
| `include-data-dirs`       | Mapping script names to data directories to include. Supports wildcards (*). | `[]`     | `{"main.py": ["./data"], "*": ["./common"]}` |
| `icon-file`               | Path to icon file (Windows only)          | `""`                                        | `"./icon.ico"`                               |
| `python-version`          | Python version to use for building        | `"3.13"`                                    | `"3.12"`                                     |
| `pyinstaller-version`     | PyInstaller version to install            | `6.11.1`                                    | `""` (use latest)                            |
| `additional-args`         | Additional PyInstaller arguments          | `""`                                        | `"--hidden-import=module"`                   |
| `pip-extra-index-url`     | Extra pip index URL                       | `https://dl.espressif.com/pypi`             | `""`                                         |
| `install-deps-command`    | Command to install project dependencies   | `"pip install --user --prefer-binary -e ."` | `"pip install -r requirements.txt"`          |
| `additional-arm-packages` | ARMv7 ONLY: Additional system packages    | `""`                                        | `"openssl libffi-dev"`                       |
| `test-command-args`       | Command arguments to test executables     | `"--help"`                                  | `"--version"`                                |

> [!IMPORTANT]
> Be careful when changing `pyinstaller-version` as it might lead to increased false positives with anti-virus software. It is recommended to check your executables with antivirus software such as [Virustotal](https://www.virustotal.com/gui/home/upload).

## Outputs

| Output                 | Description                                                    |
|------------------------|----------------------------------------------------------------|
| `executable-extension` | File extension of built executables (e.g., `.exe` for Windows) |
| `build-success`        | Whether the build was successful (`true`/`false`)              |

## Notes

- For 32-bit ARM architecture (linux-armv7), the action uses Docker containers to provide the necessary build environment
- For 64-bit ARM architecture please use the GitHub provided runners, e.g. `ubuntu-24.04-arm`. Please note that this is still in public preview so there might be some changes to images. For more details see [available runners](https://docs.github.com/en/actions/how-tos/using-github-hosted-runners/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources).
- Windows builds automatically include `.exe` extensions
- The action automatically tests built executables using the specified test command arguments
- System packages for ARMv7 builds can be customized using the `additional-arm-packages` input. For other systems, this can be done before running this action.
- It is recommended to add `fail-fast: false` to your matrix strategy to prevent one platform failure from stopping all builds
