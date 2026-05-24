#!/usr/bin/env python3
"""
Deploy all .nss integration scripts from tests/app to a NWN module folder (temp0 by default).
Also auto-add missing NWNX include scripts from NWScript folder:
  - nwnx_events.nss
  - nwnx_httpclient.nss

Example:
  python tests/nwn/_tools/itnwn_deploy_all_nss.py --dry-run
  python tests/nwn/_tools/itnwn_deploy_all_nss.py --force-replace
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

REQUIRED_NWNX_INCLUDES = ("nwnx_events.nss", "nwnx_httpclient.nss")
RUNNER_NSS_FILES = ("nuitst_apirun.nss", "nuitst_apicfg.nss")


def default_source_dir() -> Path:
    # .../tests/nwn/_tools -> .../tests/app
    return Path(__file__).resolve().parent.parent.parent / "app"


def default_temp0_dir() -> Path:
    return Path.home() / "Documents" / "Neverwinter Nights" / "modules" / "temp0"


def default_nwscript_dir() -> Path:
    return Path.home() / "Documents" / "NWScript"


def api_runner_dir() -> Path:
    return Path(__file__).resolve().parent.parent / "api_runner"


def collect_nss_files(source_dir: Path) -> list[Path]:
    files: list[Path] = []
    for path in source_dir.rglob("*.nss"):
        if not path.is_file():
            continue
        if "_tools" in {part.lower() for part in path.parts}:
            continue
        files.append(path)
    files.sort(key=lambda p: str(p).lower())
    return files


def validate_basename_length(files: list[Path]) -> list[str]:
    errors: list[str] = []
    for file_path in files:
        if len(file_path.stem) > 16:
            errors.append(f"{file_path.name}: basename exceeds 16 chars")
    return errors


def find_duplicates(files: list[Path]) -> list[str]:
    seen: dict[str, Path] = {}
    duplicates: list[str] = []
    for file_path in files:
        key = file_path.name.lower()
        if key in seen:
            duplicates.append(file_path.name)
        else:
            seen[key] = file_path
    return sorted(set(duplicates), key=str.lower)


def collect_required_nwnx_includes(
    module_path: Path,
    nwscript_dir: Path,
    force_replace: bool,
) -> tuple[list[Path], list[str]]:
    existing_names = {p.name.lower() for p in module_path.glob("*.nss") if p.is_file()}
    includes: list[Path] = []
    missing: list[str] = []

    for include_name in REQUIRED_NWNX_INCLUDES:
        if not force_replace and include_name.lower() in existing_names:
            continue
        candidate = nwscript_dir / include_name
        if candidate.exists() and candidate.is_file():
            includes.append(candidate)
        else:
            missing.append(include_name)

    return includes, missing


def collect_runner_nss_files() -> tuple[list[Path], list[str]]:
    base = api_runner_dir()
    files: list[Path] = []
    missing: list[str] = []
    for name in RUNNER_NSS_FILES:
        path = base / name
        if path.exists() and path.is_file():
            files.append(path)
        else:
            missing.append(name)
    return files, missing


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Deploy all tests/app .nss scripts into temp0.")
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=default_source_dir(),
        help="Source folder to scan recursively for .nss files (default: tests/app).",
    )
    parser.add_argument(
        "--module-path",
        type=Path,
        default=default_temp0_dir(),
        help="Destination NWN module path (default: ~/Documents/Neverwinter Nights/modules/temp0).",
    )
    parser.add_argument(
        "--nwnscript-dir",
        type=Path,
        default=default_nwscript_dir(),
        help="Source folder with NWNX include scripts (default: ~/Documents/NWScript).",
    )
    parser.add_argument(
        "--force-replace",
        action="store_true",
        help="Allow overwriting existing .nss files in module path.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be copied without writing files.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_dir = args.source_dir.resolve()
    module_path = args.module_path.resolve()
    nwscript_dir = args.nwnscript_dir.resolve()

    if not source_dir.exists() or not source_dir.is_dir():
        print(f"ERROR: source dir not found: {source_dir}", file=sys.stderr)
        return 1
    if not module_path.exists() or not module_path.is_dir():
        print(f"ERROR: module path not found: {module_path}", file=sys.stderr)
        return 1
    if not nwscript_dir.exists() or not nwscript_dir.is_dir():
        print(f"ERROR: NWScript dir not found: {nwscript_dir}", file=sys.stderr)
        return 1

    incoming = collect_nss_files(source_dir)
    runner_nss, missing_runner = collect_runner_nss_files()
    if missing_runner:
        print("ERROR: missing required runner scripts:", file=sys.stderr)
        for name in missing_runner:
            print(f"- {name} (expected in {api_runner_dir()})", file=sys.stderr)
        return 1
    required_includes, missing_includes = collect_required_nwnx_includes(
        module_path=module_path,
        nwscript_dir=nwscript_dir,
        force_replace=args.force_replace,
    )
    incoming = incoming + runner_nss + required_includes
    if not incoming:
        print(f"ERROR: no .nss files found in {source_dir}", file=sys.stderr)
        return 1
    if missing_includes:
        print("ERROR: missing required NWNX include scripts:", file=sys.stderr)
        for name in missing_includes:
            print(f"- {name} (expected in {nwscript_dir})", file=sys.stderr)
        return 1

    name_errors = validate_basename_length(incoming)
    if name_errors:
        print("ERROR: basename length validation failed:", file=sys.stderr)
        for err in name_errors:
            print(f"- {err}", file=sys.stderr)
        return 1

    duplicates = find_duplicates(incoming)
    if duplicates:
        print("ERROR: duplicate .nss filenames in source set:", file=sys.stderr)
        for name in duplicates:
            print(f"- {name}", file=sys.stderr)
        return 1

    existing_names = {p.name.lower() for p in module_path.glob("*.nss") if p.is_file()}
    collisions = sorted({p.name for p in incoming if p.name.lower() in existing_names}, key=str.lower)
    if collisions and not args.force_replace:
        print("ERROR: name collision in module path (use --force-replace):", file=sys.stderr)
        for name in collisions:
            print(f"- {name}", file=sys.stderr)
        return 1

    print(f"Source:      {source_dir}")
    print(f"Module path: {module_path}")
    print(f"NWScript:    {nwscript_dir}")
    print(f"Found .nss:  {len(incoming)}")
    print(f"Runner nss:  {len(runner_nss)}")
    if required_includes:
        print(f"NWNX deps:   {len(required_includes)}")
    if collisions:
        print(f"Collisions:  {len(collisions)} (will overwrite)")

    if args.dry_run:
        print("\nDry-run file list:")
        for src in incoming:
            if source_dir in src.parents:
                rel = src.relative_to(source_dir).as_posix()
                print(f"- {rel} -> {src.name}")
            elif api_runner_dir() in src.parents:
                print(f"- [api_runner] {src.name} -> {src.name}")
            else:
                print(f"- [NWScript] {src.name} -> {src.name}")
        return 0

    copied = 0
    for src in incoming:
        dst = module_path / src.name
        shutil.copy2(src, dst)
        copied += 1

    print(f"\nDeployed {copied} script(s) to {module_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
