#!/bin/bash

# Test built executables
# Usage: ./test_executables.sh [scripts] [script_names] [output_dir] [exe_extension] [test_args]

set -e

SCRIPTS="${1}"
SCRIPT_NAMES="${2}"
OUTPUT_DIR="${3}"
EXE_EXTENSION="${4}"
TEST_ARGS="${5:---help}"

echo "Testing built executables..."

IFS=' ' read -ra PYTHON_FILES <<< "$SCRIPTS"
IFS=' ' read -ra SCRIPT_NAMES_ARRAY <<< "$SCRIPT_NAMES"

for i in "${!PYTHON_FILES[@]}"; do
    file="${PYTHON_FILES[$i]}"

    # Determine executable name
    if [ -n "$SCRIPT_NAMES" ] && [ $i -lt ${#SCRIPT_NAMES_ARRAY[@]} ]; then
        custom_name="${SCRIPT_NAMES_ARRAY[$i]}"
        executable="$OUTPUT_DIR/${custom_name}${EXE_EXTENSION}"
    else
        base_name=$(basename "$file" .py)
        executable="$OUTPUT_DIR/${base_name}${EXE_EXTENSION}"
    fi

    echo "Testing $executable..."
    if [ -f "$executable" ]; then
        echo "✓ $executable exists ($(du -h "$executable" | cut -f1))"
        if "$executable" $TEST_ARGS; then
            echo "✓ $executable runs successfully"
        else
            echo "⚠ $executable may have issues"
            exit 1
        fi
    else
        echo "✗ $executable not found"
        exit 1
    fi
done

echo "All executables tested successfully"
