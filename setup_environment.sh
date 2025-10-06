#!/bin/bash

# Setup Python environment for PyInstaller builds
# Usage: ./setup_environment.sh [pyinstaller_version] [extra_index_url] [install_deps_command]

set -e

PYINSTALLER_VERSION="${1:-6.11.1}"
EXTRA_INDEX_URL="${2:-}"
INSTALL_DEPS_COMMAND="${3:-uv pip install -e .}"

echo "Setting up Python environment..."
echo "PyInstaller version: $PYINSTALLER_VERSION"

# Set Python package extra index if provided
if [ -n "$EXTRA_INDEX_URL" ]; then
    export UV_INDEX="$EXTRA_INDEX_URL"
    export UV_INDEX_STRATEGY="unsafe-best-match"
    echo "Using extra Python package index: $EXTRA_INDEX_URL"
fi

# Install PyInstaller
if [ -z "$PYINSTALLER_VERSION" ]; then
    uv pip install pyinstaller
else
    uv pip install pyinstaller==$PYINSTALLER_VERSION
fi

# Install dependencies
echo "Installing project dependencies..."
$INSTALL_DEPS_COMMAND

echo "Environment setup completed successfully"
