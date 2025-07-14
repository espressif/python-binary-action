#!/bin/bash

# Build Python scripts with PyInstaller
# Usage: ./build_with_pyinstaller.sh [python_version] [target_platform] [output_dir] [scripts] [script_names] [icon_file] [include_data_dirs] [data_separator] [additional_args]

set -e

# Parse arguments
PYTHON_VERSION="${1:-python}"
TARGET_PLATFORM="${2}"
OUTPUT_DIR="${3}"
SCRIPTS="${4}"
SCRIPT_NAMES="${5}"
ICON_FILE="${6}"
INCLUDE_DATA_DIRS="${7}"
DATA_SEPARATOR="${8}"
ADDITIONAL_ARGS="${9}"

echo "Building with PyInstaller..."
echo "Python version: $PYTHON_VERSION"
echo "Target platform: $TARGET_PLATFORM"
echo "Output directory: $OUTPUT_DIR"
echo "Scripts: $SCRIPTS"
echo "Script names: $SCRIPT_NAMES"

# Build each Python file
IFS=' ' read -ra PYTHON_FILES <<< "$SCRIPTS"
IFS=' ' read -ra SCRIPT_NAMES_ARRAY <<< "$SCRIPT_NAMES"

for i in "${!PYTHON_FILES[@]}"; do
  file="${PYTHON_FILES[$i]}"
  echo "Building $file for $TARGET_PLATFORM..."

  # Start building the command
  cmd="$PYTHON_VERSION -m PyInstaller --onefile --distpath=$OUTPUT_DIR"

  # Add custom name if provided
  if [ -n "$SCRIPT_NAMES" ] && [ $i -lt ${#SCRIPT_NAMES_ARRAY[@]} ]; then
    custom_name="${SCRIPT_NAMES_ARRAY[$i]}"
    cmd="$cmd --name=$custom_name"
    echo "Using custom name: $custom_name"
  fi

  # Windows-specific options
  if [ "$TARGET_PLATFORM" = "windows-amd64" ]; then
    if [ -n "$ICON_FILE" ]; then
      cmd="$cmd --icon=$ICON_FILE"
    fi
  fi

  # Add include-data-dirs using Python script
  if [ -n "$INCLUDE_DATA_DIRS" ]; then
    echo "Processing include-data-dirs for $file..."
    include_flags=$($PYTHON_VERSION $GITHUB_ACTION_PATH/process_include_dirs.py "$INCLUDE_DATA_DIRS" "$DATA_SEPARATOR" "$file")
    echo "Include flags result: '$include_flags'"
    if [ -n "$include_flags" ]; then
      cmd="$cmd $include_flags"
      echo "Added include flags to command"
    else
      echo "No include flags generated"
    fi
  fi

  # Add additional arguments
  if [ -n "$ADDITIONAL_ARGS" ]; then
    cmd="$cmd $ADDITIONAL_ARGS"
  fi

  # Add the file to build
  cmd="$cmd $file"

  echo "Executing: $cmd"
  eval "$cmd"
done

echo "Build completed successfully"
