# /// script
# requires-python = ">=3.10"
# dependencies = ["pyinstaller>=6,<7"]
# ///
"""Fail if a PyInstaller onefile executable requires a newer glibc than allowed.

Checks the bootloader and every shared library and extension module bundled in the
archive, including those that are not loaded when the executable starts.
"""

import argparse
import re
import sys
from collections.abc import Iterator
from pathlib import Path

from PyInstaller.archive.readers import PKG_ITEM_BINARY, CArchiveReader

# Symbol version names (e.g. GLIBC_2.31) are stored as plain strings in the ELF dynamic string table
GLIBC_VERSION_RE = re.compile(rb"GLIBC_(\d+)\.(\d+)")


def parse_version(value: str) -> tuple[int, int]:
    major, minor = value.split(".")
    return int(major), int(minor)


def format_version(version: tuple[int, int]) -> str:
    return ".".join(map(str, version))


def required_glibc(data: bytes) -> tuple[int, int] | None:
    versions = [(int(major), int(minor)) for major, minor in GLIBC_VERSION_RE.findall(data)]
    return max(versions, default=None)


def bundled_binaries(executable: Path) -> Iterator[tuple[str, bytes]]:
    yield executable.name, executable.read_bytes()
    archive = CArchiveReader(str(executable))
    for name, (*_, typecode) in archive.toc.items():
        if typecode == PKG_ITEM_BINARY:
            yield name, archive.extract(name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executables", nargs="+", type=Path, help="PyInstaller onefile executables to check")
    parser.add_argument("--max-glibc", default="2.31", help="Highest glibc version the executables may require")
    args = parser.parse_args()
    max_allowed = parse_version(args.max_glibc)

    failed = False
    for executable in args.executables:
        highest = (0, 0)
        for name, data in bundled_binaries(executable):
            required = required_glibc(data)
            if required is None:
                continue
            highest = max(highest, required)
            if required > max_allowed:
                print(f"{executable}: {name} requires GLIBC_{format_version(required)}")
                failed = True
        print(f"{executable}: highest required glibc {format_version(highest)} (allowed {args.max_glibc})")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
