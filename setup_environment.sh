#!/bin/bash

# Setup Python environment for PyInstaller builds
# Usage: ./setup_environment.sh [python_version] [pyinstaller_version] [pip_extra_index_url] [install_deps_command]

set -e

PYTHON_VERSION="${1:-python}"
PYINSTALLER_VERSION="${2:-6.11.1}"
PIP_EXTRA_INDEX_URL="${3:-}"
INSTALL_DEPS_COMMAND="${4:-pip install --user --prefer-binary -e .}"

echo "Setting up Python environment..."
echo "Python version: $PYTHON_VERSION"
echo "PyInstaller version: $PYINSTALLER_VERSION"

# Set pip extra index if provided
if [ -n "$PIP_EXTRA_INDEX_URL" ]; then
    export PIP_EXTRA_INDEX_URL="$PIP_EXTRA_INDEX_URL"
    echo "Using extra pip index: $PIP_EXTRA_INDEX_URL"
fi

# Install PyInstaller
if [ -z "$PYINSTALLER_VERSION" ]; then
    $PYTHON_VERSION -m pip install pyinstaller
else
    $PYTHON_VERSION -m pip install pyinstaller==$PYINSTALLER_VERSION
fi

# Install dependencies
echo "Installing project dependencies..."
$PYTHON_VERSION -m $INSTALL_DEPS_COMMAND

echo "Environment setup completed successfully"
