#!/usr/bin/env python3
"""
Process include-data-dirs JSON and generate PyInstaller arguments
Supports per-script configuration with wildcard support
"""

import json
import argparse
import fnmatch
import sys


def fix_windows_paths(include_dirs_json: str) -> str:
    """Fix Windows paths in the include directories"""
    if sys.platform == "win32":
        include_dirs_json = include_dirs_json.replace("\\", "/")
    return include_dirs_json


def process_include_dirs(include_dirs_json: str, data_separator: str, target_script: str) -> str:
    """Convert include directories JSON to PyInstaller --add-data flags
    for a specific script"""
    try:
        include_dirs_config = json.loads(fix_windows_paths(include_dirs_json))
        if not include_dirs_config:
            return ""

        # For simplicity, we also support simple list format
        # This is equivalent to the dict format with wildcard
        if isinstance(include_dirs_config, list):
            # Simple format: apply to all scripts
            include_dirs = include_dirs_config
        elif isinstance(include_dirs_config, dict):
            # Dict format: per-script configuration
            include_dirs = []
            processed_patterns = set()

            # Check for wildcard entries first
            for pattern, dirs in include_dirs_config.items():
                if pattern == "*" or fnmatch.fnmatch(target_script, pattern):
                    if isinstance(dirs, list):
                        include_dirs.extend(dirs)
                    else:
                        include_dirs.append(dirs)
                    processed_patterns.add(pattern)

            # Check for exact script name (only if not already processed by wildcard)
            if target_script in include_dirs_config and target_script not in processed_patterns:
                dirs = include_dirs_config[target_script]
                if isinstance(dirs, list):
                    include_dirs.extend(dirs)
                else:
                    include_dirs.append(dirs)
        else:
            return ""

        if not include_dirs:
            return ""

        flags = []
        for item in include_dirs:
            flags.append(f"--add-data='{item}{data_separator}{item}'")

        return " ".join(flags)
    except (json.JSONDecodeError, KeyError, TypeError) as e:
        print(
            f"Warning: Error processing include dirs for {target_script}: {e}",
            file=sys.stderr,
        )
        return ""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Process include directories for PyInstaller",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Simple list format (applies to all scripts)
  python process_include_dirs.py '["./data"]' ':' 'main.py'

  # Dict format (per-script configuration with wildcard support)
  python process_include_dirs.py '{"main.py": ["./assets"], "*": ["./common"]}' ':' 'main.py'
        """,  # noqa: E501
    )
    parser.add_argument("include_dirs", help="JSON string of include directories")
    parser.add_argument(
        "data_separator",
        help="Data separator for PyInstaller --add-data (; for Windows, : for Unix)",
    )
    parser.add_argument("target_script", help="Target script name for filtering")

    args = parser.parse_args()
    result = process_include_dirs(args.include_dirs, args.data_separator, args.target_script)
    print(result)


if __name__ == "__main__":
    main()
