#!/usr/bin/env python3
"""
ITNWN API runner server (MVP).

Endpoints:
  GET  /health
  GET  /nui-runner/tests
  POST /nui-runner/start
  POST /nui-runner/results
  POST /nui-runner/finish
  GET  /nui-runner/summary

Default host/port:
  127.0.0.1:51871
Override with CLI args or env:
  ITNWN_API_HOST, ITNWN_API_PORT

TLS cert/key (HTTPS required):
  --tls-cert / --tls-key
  ITNWN_TLS_CERT, ITNWN_TLS_KEY
"""

from __future__ import annotations

import argparse
import atexit
import hashlib
import json
import os
import re
import socket
import shutil
import ssl
import subprocess
import threading
import time
from queue import Empty, Queue
from dataclasses import dataclass, field
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


SAFE_RESREF = re.compile(r"^[A-Za-z0-9_]+$")
MAX_RESREF_LEN = 16
REQUIRED_NWNX_INCLUDES = ("nwnx_events.nss", "nwnx_httpclient.nss")
RUNNER_NSS_FILES = ("nuitst_apirun.nss", "nuitst_apicfg.nss")
EXCLUDED_TEST_CASE_IDS = {"nuitest_menu"}
LAUNCHER_PREFIX = "itap_"


def pid_is_running(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    except Exception:
        return False
    return True


def acquire_server_lock(lock_path: Path, host: str, port: int) -> None:
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    if lock_path.exists():
        try:
            existing = json.loads(lock_path.read_text(encoding="utf-8"))
        except Exception:
            existing = {}
        old_pid = int(existing.get("pid", 0) or 0)
        if pid_is_running(old_pid) and old_pid != os.getpid():
            old_host = str(existing.get("host", "unknown"))
            old_port = int(existing.get("port", 0) or 0)
            old_started = str(existing.get("started_at", "unknown"))
            raise RuntimeError(
                "API runner lock already held.\n"
                f"- pid: {old_pid}\n"
                f"- host: {old_host}\n"
                f"- port: {old_port}\n"
                f"- started_at: {old_started}\n"
                f"Lock file: {lock_path}\n"
                "Stop existing API runner process before starting a new one."
            )

    payload = {
        "pid": os.getpid(),
        "host": host,
        "port": port,
        "started_at": utc_now_iso(),
    }
    lock_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def _cleanup_lock() -> None:
        try:
            if lock_path.exists():
                current = json.loads(lock_path.read_text(encoding="utf-8"))
                if int(current.get("pid", 0) or 0) == os.getpid():
                    lock_path.unlink()
        except Exception:
            pass

    atexit.register(_cleanup_lock)


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def canonicalize_json(value: Any) -> Any:
    if isinstance(value, dict):
        out: dict[str, Any] = {}
        for key in sorted(value.keys(), key=lambda x: str(x)):
            out[str(key)] = canonicalize_json(value[key])
        return out
    if isinstance(value, list):
        return [canonicalize_json(v) for v in value]
    return value


def canonical_json_string(value: Any) -> str:
    normalized = canonicalize_json(value)
    return json.dumps(normalized, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def resolve_default_tests_root() -> Path:
    # .../tests/nwn/api_runner -> .../tests/app
    tests_dir = Path(__file__).resolve().parent.parent.parent
    return tests_dir / "app"


def resolve_default_manifest() -> Path:
    # Optional legacy manifest; ignored by default when auto-discovering from tests/app
    return Path(__file__).resolve().parent / "tests_manifest.json"


def resolve_default_artifacts_root() -> Path:
    tests_dir = Path(__file__).resolve().parent.parent.parent
    return tests_dir / "_artifacts" / "api_runner"


def resolve_default_module_path() -> Path:
    return Path.home() / "Documents" / "Neverwinter Nights" / "modules" / "temp0"


def resolve_default_nwscript_dir() -> Path:
    return Path.home() / "Documents" / "NWScript"


def resolve_default_tls_cert() -> Path:
    return Path(__file__).resolve().parent / "certs" / "itnwn_api_localhost.crt"


def resolve_default_tls_key() -> Path:
    return Path(__file__).resolve().parent / "certs" / "itnwn_api_localhost.key"


def read_env_port(default: int) -> int:
    raw = os.getenv("ITNWN_API_PORT", "").strip()
    if not raw:
        return default
    try:
        port = int(raw)
    except ValueError:
        return default
    if 1 <= port <= 65535:
        return port
    return default


def read_env_host(default: str) -> str:
    raw = os.getenv("ITNWN_API_HOST", "").strip()
    return raw or default


def read_env_module_path(default: Path) -> Path:
    raw = os.getenv("ITNWN_MODULE_PATH", "").strip()
    if not raw:
        return default
    return Path(raw)


def read_env_nwscript_dir(default: Path) -> Path:
    raw = os.getenv("ITNWN_NWSCRIPT_DIR", "").strip()
    if not raw:
        return default
    return Path(raw)


def read_env_tls_cert(default: Path) -> Path:
    raw = os.getenv("ITNWN_TLS_CERT", "").strip()
    if not raw:
        return default
    return Path(raw)


def read_env_tls_key(default: Path) -> Path:
    raw = os.getenv("ITNWN_TLS_KEY", "").strip()
    if not raw:
        return default
    return Path(raw)


def collect_nss_files(source_dir: Path) -> list[Path]:
    out: list[Path] = []
    for path in source_dir.rglob("*.nss"):
        if not path.is_file():
            continue
        if "_tools" in {part.lower() for part in path.parts}:
            continue
        out.append(path)
    out.sort(key=lambda p: str(p).lower())
    return out


def validate_nss_set(files: list[Path]) -> list[str]:
    errors: list[str] = []
    seen_names: set[str] = set()
    for file_path in files:
        stem = file_path.stem
        name_key = file_path.name.lower()
        if len(stem) > MAX_RESREF_LEN:
            errors.append(f"{file_path.name}: basename exceeds {MAX_RESREF_LEN} chars")
        if not SAFE_RESREF.match(stem):
            errors.append(f"{file_path.name}: invalid basename '{stem}' (allowed: A-Z, 0-9, _)")
        if name_key in seen_names:
            errors.append(f"{file_path.name}: duplicate filename in source set")
        else:
            seen_names.add(name_key)
    return errors


def files_are_identical(src: Path, dst: Path) -> bool:
    try:
        if src.stat().st_size != dst.stat().st_size:
            return False
        return src.read_bytes() == dst.read_bytes()
    except Exception:
        return False


def copy_nss_file(src: Path, dst: Path) -> None:
    try:
        shutil.copy2(src, dst)
    except PermissionError as exc:
        raise RuntimeError(
            "Permission denied while syncing .nss to temp0.\n"
            f"- src: {src}\n"
            f"- dst: {dst}\n"
            "Likely file lock by active NWN process. Stop server/client or rerun with --skip-nss-sync "
            "if temp0 is already up to date."
        ) from exc


def deploy_nss_to_module(source_dir: Path, module_path: Path, force_replace: bool) -> tuple[int, list[str], int]:
    if not source_dir.exists() or not source_dir.is_dir():
        raise RuntimeError(f"Source dir not found: {source_dir}")
    if not module_path.exists() or not module_path.is_dir():
        raise RuntimeError(
            f"Module path (temp0) not found: {module_path}\n"
            "Create/point to a valid temp0 folder first, then restart API."
        )

    incoming = collect_nss_files(source_dir)
    if not incoming:
        raise RuntimeError(f"No .nss files found in source dir: {source_dir}")

    errors = validate_nss_set(incoming)
    if errors:
        detail = "\n".join(f"- {err}" for err in errors)
        raise RuntimeError(f"NSS validation failed:\n{detail}")

    collisions: list[str] = []
    copied = 0
    skipped_identical = 0

    for src in incoming:
        dst = module_path / src.name
        if dst.exists() and dst.is_file():
            if files_are_identical(src, dst):
                skipped_identical += 1
                continue
            if not force_replace:
                collisions.append(src.name)
                continue
        copy_nss_file(src, dst)
        copied += 1

    if collisions and not force_replace:
        detail = "\n".join(f"- {name}" for name in sorted(set(collisions), key=str.lower))
        raise RuntimeError(
            "Refusing to overwrite changed .nss in module path (force disabled).\n"
            "Collisions:\n"
            f"{detail}"
        )

    return copied, sorted(set(collisions), key=str.lower), skipped_identical


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


def deploy_all_nss_with_required_includes(
    source_dir: Path,
    module_path: Path,
    nwscript_dir: Path,
    force_replace: bool,
) -> tuple[int, list[str], int, int]:
    if not nwscript_dir.exists() or not nwscript_dir.is_dir():
        raise RuntimeError(
            f"NWScript dir not found: {nwscript_dir}\n"
            "Set --nwnscript-dir (or ITNWN_NWSCRIPT_DIR) to folder containing nwnx_events.nss and nwnx_httpclient.nss."
        )

    required_includes, missing_includes = collect_required_nwnx_includes(
        module_path=module_path,
        nwscript_dir=nwscript_dir,
        force_replace=force_replace,
    )
    if missing_includes:
        detail = "\n".join(f"- {name}" for name in missing_includes)
        raise RuntimeError(
            "Missing required NWNX include scripts.\n"
            f"Expected in: {nwscript_dir}\n"
            f"{detail}"
        )

    copied_app, collisions, skipped_app = deploy_nss_to_module(source_dir, module_path, force_replace)
    copied_required = 0
    for src in required_includes:
        dst = module_path / src.name
        if dst.exists() and dst.is_file() and files_are_identical(src, dst):
            continue
        copy_nss_file(src, dst)
        copied_required += 1
    return copied_app, collisions, copied_required, skipped_app


def collect_runner_nss_files() -> list[Path]:
    runner_dir = Path(__file__).resolve().parent
    files: list[Path] = []
    missing: list[str] = []
    for name in RUNNER_NSS_FILES:
        path = runner_dir / name
        if path.exists() and path.is_file():
            files.append(path)
        else:
            missing.append(name)
    if missing:
        detail = "\n".join(f"- {name}" for name in missing)
        raise RuntimeError(
            "Missing runner scripts in api_runner directory.\n"
            f"{detail}"
        )
    return files


def compile_runner_ncs(module_path: Path, nwscript_dir: Path, skip_compile: bool) -> int:
    if skip_compile:
        return 0

    nwnsc = module_path.parent / "nwnsc.exe"
    if not nwnsc.exists() or not nwnsc.is_file():
        raise RuntimeError(
            f"nwnsc.exe not found: {nwnsc}\n"
            "Expected next to module folder (..\\modules\\nwnsc.exe)."
        )

    home_dir = module_path.parent.parent
    include_path = f"{module_path};{nwscript_dir}"
    compiled = 0

    for name in RUNNER_NSS_FILES:
        nss_path = module_path / name
        if not nss_path.exists() or not nss_path.is_file():
            raise RuntimeError(f"Runner source missing in module path: {nss_path}")
        ncs_path = module_path / f"{nss_path.stem}.ncs"

        cmd = [
            str(nwnsc),
            "-h",
            str(home_dir),
            "-l",
            "-i",
            include_path,
            "-o",
            "-r",
            str(ncs_path),
            str(nss_path),
        ]
        proc = subprocess.run(
            cmd,
            cwd=str(module_path),
            capture_output=True,
            text=True,
            timeout=90,
            check=False,
        )
        if proc.returncode != 0:
            out = (proc.stdout or "").strip()
            err = (proc.stderr or "").strip()
            detail = (out + "\n" + err).strip()
            if len(detail) > 4000:
                detail = detail[-4000:]
            raise RuntimeError(
                f"Failed to compile runner script: {name}\n"
                f"Command: {' '.join(cmd)}\n"
                f"Output:\n{detail}"
            )
        compiled += 1

    return compiled


def deploy_extra_nss_files(extra_files: list[Path], module_path: Path, force_replace: bool) -> tuple[int, list[str], int]:
    if not extra_files:
        return 0, [], 0

    collisions: list[str] = []
    copied = 0
    skipped_identical = 0
    for src in extra_files:
        dst = module_path / src.name
        if dst.exists() and dst.is_file():
            if files_are_identical(src, dst):
                skipped_identical += 1
                continue
            if not force_replace:
                collisions.append(src.name)
                continue
        copy_nss_file(src, dst)
        copied += 1

    if collisions and not force_replace:
        detail = "\n".join(f'- {name}' for name in sorted(set(collisions), key=str.lower))
        raise RuntimeError(
            'Refusing to overwrite generated wrapper .nss in module path (force disabled).\n'
            'Collisions:\n'
            f'{detail}'
        )

    return copied, sorted(set(collisions), key=str.lower), skipped_identical


def normalize_test_case(raw: dict[str, Any], default_delay_ms: int, index: int) -> dict[str, Any]:
    case_id = str(raw.get("case_id") or f"case_{index}").strip()
    script_resref = str(raw.get("script_resref") or "").strip()
    expected_window_id = str(raw.get("expected_window_id") or "ITNWN_UNKNOWN").strip()
    capture_test = str(raw.get("capture_test") or "").strip()
    delay_ms_raw = raw.get("delay_ms", default_delay_ms)
    try:
        delay_ms = int(delay_ms_raw)
    except (TypeError, ValueError):
        delay_ms = default_delay_ms
    if delay_ms < 100:
        delay_ms = 100

    return {
        "case_id": case_id,
        "script_resref": script_resref,
        "expected_window_id": expected_window_id,
        "capture_test": capture_test,
        "delay_ms": delay_ms,
    }


def validate_tests(cases: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    seen_case_ids: set[str] = set()
    seen_scripts: set[str] = set()

    for idx, case in enumerate(cases):
        case_id = case["case_id"]
        script_resref = case["script_resref"]

        if not case_id:
            errors.append(f"[{idx}] empty case_id")
        elif case_id in seen_case_ids:
            errors.append(f"[{idx}] duplicate case_id '{case_id}'")
        else:
            seen_case_ids.add(case_id)

        if not script_resref:
            errors.append(f"[{idx}] empty script_resref")
            continue

        if len(script_resref) > MAX_RESREF_LEN:
            errors.append(f"[{idx}] script_resref '{script_resref}' exceeds {MAX_RESREF_LEN} chars")
        if not SAFE_RESREF.match(script_resref):
            errors.append(f"[{idx}] script_resref '{script_resref}' must match [A-Za-z0-9_]+")
        if script_resref in seen_scripts:
            errors.append(f"[{idx}] duplicate script_resref '{script_resref}'")
        else:
            seen_scripts.add(script_resref)

    return errors


WINDOW_CONST_RE = re.compile(r'(?mi)^\s*const\s+string\s+[A-Za-z0-9_]*WIN[A-Za-z0-9_]*\s*=\s*"([^"]+)"')
OBJ_ENTRY_RE = re.compile(r'(?mi)^\s*void\s+([A-Za-z0-9_]+)\s*\(\s*object\s+oPC\s*\)')
MAIN_RE = re.compile(r'(?mi)^\s*void\s+main\s*\(')


def detect_expected_window_id(script_text: str) -> str:
    m = WINDOW_CONST_RE.search(script_text)
    if not m:
        return 'ITNWN_UNKNOWN'
    win_id = m.group(1).strip()
    return win_id or 'ITNWN_UNKNOWN'


def detect_entry_function(script_text: str) -> str | None:
    matches = [m.group(1) for m in OBJ_ENTRY_RE.finditer(script_text)]
    if not matches:
        return None

    preferred_suffixes = ('Open', 'SwapOpen', 'Show', 'Start')
    for name in matches:
        for suffix in preferred_suffixes:
            if name.endswith(suffix):
                return name

    if len(matches) == 1:
        return matches[0]

    return matches[0]


def make_wrapper_resref(source_rel: str) -> str:
    digest = hashlib.sha1(source_rel.lower().encode('utf-8')).hexdigest()[:11]
    return f'{LAUNCHER_PREFIX}{digest}'


def build_entry_wrapper_script(source_stem: str, entry_func: str) -> str:
    return (
        '// Auto-generated static launcher (entry wrapper).\n'
        f'#include "{source_stem}"\n\n'
        'void main()\n'
        '{\n'
        '    object oPC = GetLastUsedBy();\n'
        '    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))\n'
        '    {\n'
        '        oPC = GetFirstPC();\n'
        '    }\n'
        '    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;\n\n'
        f'    {entry_func}(oPC);\n'
        '}\n'
    )


def build_main_proxy_launcher_script(source_stem: str) -> str:
    return (
        '// Auto-generated static launcher (main proxy).\n'
        'void main()\n'
        '{\n'
        '    object oPC = GetLastUsedBy();\n'
        '    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC))\n'
        '    {\n'
        '        oPC = GetFirstPC();\n'
        '    }\n'
        '    if (!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;\n\n'
        f'    ExecuteScript("{source_stem}", oPC);\n'
        '}\n'
    )


def ensure_static_launcher(
    tests_root: Path,
    source_script: Path,
    script_text: str,
    entry_func: str | None,
) -> tuple[Path, bool]:
    source_rel = str(source_script.relative_to(tests_root)).replace('\\', '/')
    launcher_resref = make_wrapper_resref(source_rel)
    launcher_path = source_script.parent / f'{launcher_resref}.nss'

    # If source already is launcher, avoid recursion.
    if source_script.stem.lower() == launcher_resref.lower():
        return source_script, False

    has_main = MAIN_RE.search(script_text) is not None
    if has_main:
        content = build_main_proxy_launcher_script(source_script.stem)
    else:
        if not entry_func:
            raise ValueError(f"No callable entry function detected in {source_script}")
        content = build_entry_wrapper_script(source_script.stem, entry_func)

    if launcher_path.exists():
        existing = launcher_path.read_text(encoding='utf-8', errors='ignore')
        if existing == content:
            return launcher_path, False

    launcher_path.write_text(content, encoding='utf-8')
    return launcher_path, True


def auto_discover_tests(
    tests_root: Path,
    default_delay_ms: int,
) -> tuple[list[dict[str, Any]], int]:
    if not tests_root.exists() or not tests_root.is_dir():
        raise ValueError(f'Tests root not found: {tests_root}')

    discovered: list[dict[str, Any]] = []
    launchers_written = 0

    folder_candidates = [
        d for d in sorted(tests_root.iterdir(), key=lambda p: p.name.lower())
        if d.is_dir() and not d.name.startswith('_') and d.name.lower() != 'assets'
    ]

    for folder in folder_candidates:
        case_id = folder.name
        if case_id.lower() in EXCLUDED_TEST_CASE_IDS:
            continue

        nss_files = [
            p for p in sorted(folder.glob('*.nss'), key=lambda x: x.name.lower())
            if not p.stem.lower().endswith('_ev') and not p.stem.lower().startswith(LAUNCHER_PREFIX)
        ]
        if not nss_files:
            continue

        preferred = folder / f'{folder.name}.nss'
        ordered: list[Path] = []
        if preferred in nss_files:
            ordered.append(preferred)
        for path in nss_files:
            if path not in ordered:
                ordered.append(path)

        chosen_script: Path | None = None
        for script_path in ordered:
            script_text = script_path.read_text(encoding='utf-8', errors='ignore')
            has_main = MAIN_RE.search(script_text) is not None
            has_entry = detect_entry_function(script_text) is not None
            if has_main or has_entry:
                chosen_script = script_path
                break

        if chosen_script is None:
            continue

        script_text = chosen_script.read_text(encoding='utf-8', errors='ignore')
        expected_window_id = detect_expected_window_id(script_text)
        entry_func = detect_entry_function(script_text)
        capture_test = folder.name if any(folder.glob("*.jui")) else ""
        source_rel = str(chosen_script.relative_to(tests_root)).replace('\\', '/')
        launcher_path, was_written = ensure_static_launcher(
            tests_root=tests_root,
            source_script=chosen_script,
            script_text=script_text,
            entry_func=entry_func,
        )
        if was_written:
            launchers_written += 1

        discovered.append(
            {
                'case_id': case_id,
                'script_resref': launcher_path.stem,
                'expected_window_id': expected_window_id,
                'capture_test': capture_test,
                'delay_ms': default_delay_ms,
                'source_script': source_rel,
                'launcher_script': str(launcher_path.relative_to(tests_root)).replace('\\', '/'),
            }
        )

    return discovered, launchers_written


def load_tests(
    manifest_path: Path,
    tests_root: Path,
    default_delay_ms: int,
    use_manifest: bool,
) -> tuple[list[dict[str, Any]], str, int]:
    launchers_written = 0

    if use_manifest and manifest_path.exists():
        data = json.loads(manifest_path.read_text(encoding='utf-8'))
        if isinstance(data, list):
            raw_cases = data
        elif isinstance(data, dict):
            raw_cases = data.get('tests', [])
        else:
            raise ValueError("Manifest must be JSON array or object with 'tests'.")
        if not isinstance(raw_cases, list):
            raise ValueError("Manifest 'tests' field must be an array.")

        cases = [normalize_test_case(dict(item), default_delay_ms, idx) for idx, item in enumerate(raw_cases) if isinstance(item, dict)]
        source = f'manifest:{manifest_path}'
    else:
        cases, launchers_written = auto_discover_tests(tests_root, default_delay_ms)
        source = f'auto:{tests_root}'

    errors = validate_tests(cases)
    if errors:
        detail = "\n".join(f'- {err}' for err in errors)
        raise ValueError(f'Invalid tests list:\n{detail}')

    return cases, source, launchers_written


@dataclass
class RunnerState:
    run_id: str
    tests: list[dict[str, Any]]
    tests_source: str
    tests_root: Path
    run_dir: Path
    results_ndjson: Path
    summary_path: Path
    tests_snapshot_path: Path
    capture_enabled: bool = True
    capture_port: int = 4174
    created_at: str = field(default_factory=utc_now_iso)
    started_at: str = ""
    finished_at: str = ""
    run_started: bool = False
    run_finished: bool = False
    lock: threading.Lock = field(default_factory=threading.Lock)
    results: list[dict[str, Any]] = field(default_factory=list)
    _capture_queue: Queue[tuple[str, str]] = field(default_factory=Queue, init=False)
    _capture_thread: threading.Thread | None = field(default=None, init=False)
    _capture_stop: threading.Event = field(default_factory=threading.Event, init=False)
    _tests_by_case: dict[str, dict[str, Any]] = field(default_factory=dict, init=False)

    def __post_init__(self) -> None:
        self._tests_by_case = {
            str(row.get("case_id", "")).strip(): row
            for row in self.tests
            if str(row.get("case_id", "")).strip()
        }
        if self.capture_enabled:
            self._start_capture_worker()

    @property
    def repo_root(self) -> Path:
        return self.tests_root.parent.parent

    @property
    def capture_script(self) -> Path:
        return self.tests_root.parent / "nwn" / "_tools" / "itnwn_capture_builder_result.ps1"

    @property
    def runtime_jui_dir(self) -> Path:
        return self.run_dir / "runtime_jui"

    def write_initial_files(self) -> None:
        self.run_dir.mkdir(parents=True, exist_ok=True)
        self.results_ndjson.write_text("", encoding="utf-8")
        snapshot = {
            "run_id": self.run_id,
            "created_at": self.created_at,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "run_started": self.run_started,
            "run_finished": self.run_finished,
            "tests_source": self.tests_source,
            "tests_count": len(self.tests),
            "capture_enabled": self.capture_enabled,
            "capture_port": self.capture_port,
            "tests": self.tests,
        }
        self.tests_snapshot_path.write_text(json.dumps(snapshot, indent=2, ensure_ascii=False), encoding="utf-8")
        self.flush_summary()

    def flush_summary(self) -> None:
        counts = {
            "total_results": len(self.results),
            "pass": 0,
            "fail": 0,
            "opened": 0,
            "window_id_match": 0,
            "capture_done": 0,
            "capture_failed": 0,
            "capture_pending": 0,
            "jui_match": 0,
            "jui_diff": 0,
            "jui_missing_expected": 0,
            "jui_runtime_missing_or_invalid": 0,
            "jui_expected_ambiguous": 0,
            "jui_expected_invalid": 0,
        }
        for row in self.results:
            status = str(row.get("status", "")).upper()
            if status == "PASS":
                counts["pass"] += 1
            else:
                counts["fail"] += 1
            if int(row.get("opened", 0)) != 0:
                counts["opened"] += 1
            if int(row.get("window_id_match", 0)) != 0:
                counts["window_id_match"] += 1
            cap_status = str(row.get("app_capture_status", "")).upper()
            if cap_status == "DONE":
                counts["capture_done"] += 1
            elif cap_status == "FAILED":
                counts["capture_failed"] += 1
            elif cap_status in {"QUEUED", "RUNNING"}:
                counts["capture_pending"] += 1

            jui_status = str(row.get("jui_compare_status", "")).upper()
            if jui_status == "MATCH":
                counts["jui_match"] += 1
            elif jui_status == "DIFF":
                counts["jui_diff"] += 1
            elif jui_status == "MISSING_EXPECTED":
                counts["jui_missing_expected"] += 1
            elif jui_status in {"RUNTIME_NULL", "RUNTIME_INVALID", "MISSING_RUNTIME"}:
                counts["jui_runtime_missing_or_invalid"] += 1
            elif jui_status == "AMBIGUOUS_EXPECTED":
                counts["jui_expected_ambiguous"] += 1
            elif jui_status == "EXPECTED_INVALID":
                counts["jui_expected_invalid"] += 1

        payload = {
            "run_id": self.run_id,
            "created_at": self.created_at,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "run_started": self.run_started,
            "run_finished": self.run_finished,
            "updated_at": utc_now_iso(),
            "tests_source": self.tests_source,
            "tests_count": len(self.tests),
            "capture_enabled": self.capture_enabled,
            "capture_port": self.capture_port,
            "counts": counts,
            "results": self.results,
        }
        self.summary_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")

    def mark_started(self) -> None:
        with self.lock:
            if not self.run_started:
                self.run_started = True
                self.started_at = utc_now_iso()
                self.flush_summary()

    def mark_finished(self) -> None:
        with self.lock:
            self.run_finished = True
            self.finished_at = utc_now_iso()
            self.flush_summary()

    def wait_for_capture(self, timeout_sec: float = 300.0) -> bool:
        if not self.capture_enabled:
            return True
        deadline = time.time() + timeout_sec if timeout_sec > 0 else None
        while True:
            if self._capture_queue.unfinished_tasks == 0:
                return True
            if deadline is not None and time.time() >= deadline:
                return False
            time.sleep(0.2)

    def capture_pending_count(self) -> int:
        with self.lock:
            pending = 0
            for row in self.results:
                cap_status = str(row.get("app_capture_status", "")).upper()
                if cap_status in {"QUEUED", "RUNNING"}:
                    pending += 1
            return pending

    def add_result(self, data: dict[str, Any]) -> tuple[int, dict[str, Any]]:
        with self.lock:
            row = dict(data)
            row["received_at"] = utc_now_iso()
            row["run_id"] = self.run_id
            if not row.get("case_id"):
                row["case_id"] = str(row.get("script_resref") or f"case_{len(self.results)}")

            case_id = str(row.get("case_id", "")).strip()
            self._persist_runtime_jui_and_compare(case_id, row)
            test_meta = self._tests_by_case.get(case_id, {})
            capture_test = str(test_meta.get("capture_test", "")).strip()
            if self.capture_enabled and capture_test:
                row["app_capture_test"] = capture_test
                row["app_capture_status"] = "QUEUED"
                self._capture_queue.put((case_id, capture_test))
            else:
                row["app_capture_test"] = capture_test
                row["app_capture_status"] = "DISABLED_OR_MISSING"

            self.results.append(row)
            with self.results_ndjson.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(row, ensure_ascii=False) + "\n")
            if len(self.results) >= len(self.tests):
                self.run_finished = True
                if not self.finished_at:
                    self.finished_at = utc_now_iso()
            self.flush_summary()
            return len(self.results), row

    def _resolve_case_dir(self, case_id: str) -> Path | None:
        if not case_id:
            return None
        direct = self.tests_root / case_id
        if direct.exists() and direct.is_dir():
            return direct

        test_meta = self._tests_by_case.get(case_id, {})
        source_script = str(test_meta.get("source_script", "")).strip()
        if source_script:
            maybe_dir = (self.tests_root / source_script).parent
            if maybe_dir.exists() and maybe_dir.is_dir():
                return maybe_dir
        return None

    def _select_expected_jui(self, case_id: str) -> tuple[Path | None, str, list[str]]:
        case_dir = self._resolve_case_dir(case_id)
        if case_dir is None:
            return None, "MISSING_EXPECTED", []

        jui_files = sorted(case_dir.glob("*.jui"), key=lambda p: p.name.lower())
        if not jui_files:
            return None, "MISSING_EXPECTED", []

        # Canonical priority: case_id.jui in the test folder.
        case_named = case_dir / f"{case_id}.jui"
        if case_named.exists():
            return case_named, "OK", [case_named.name]

        if len(jui_files) == 1:
            return jui_files[0], "OK", [jui_files[0].name]

        test_meta = self._tests_by_case.get(case_id, {})
        source_script = str(test_meta.get("source_script", "")).strip()
        source_stem = Path(source_script).stem.lower() if source_script else ""
        if source_stem:
            by_stem = [
                p for p in jui_files
                if p.stem.lower() == source_stem or p.stem.lower().startswith(source_stem + "_")
            ]
            if len(by_stem) == 1:
                return by_stem[0], "OK", [p.name for p in by_stem]

        return None, "AMBIGUOUS_EXPECTED", [p.name for p in jui_files]

    def _persist_runtime_jui_and_compare(self, case_id: str, row: dict[str, Any]) -> None:
        raw = row.get("user_data_dump")
        if raw is None:
            row["jui_compare_status"] = "MISSING_RUNTIME"
            row["jui_compare_note"] = "user_data_dump missing in result payload."
            return

        raw_text = str(raw).strip()
        if not raw_text:
            row["jui_compare_status"] = "MISSING_RUNTIME"
            row["jui_compare_note"] = "user_data_dump is empty."
            return

        try:
            runtime_obj = json.loads(raw_text)
        except json.JSONDecodeError as exc:
            row["jui_compare_status"] = "RUNTIME_INVALID"
            row["jui_compare_note"] = f"runtime JSON parse error: {exc}"
            return

        if runtime_obj is None:
            row["jui_compare_status"] = "RUNTIME_NULL"
            row["jui_compare_note"] = "runtime user_data_dump == null."
            return

        self.runtime_jui_dir.mkdir(parents=True, exist_ok=True)
        runtime_path = self.runtime_jui_dir / f"{case_id}.jui"
        runtime_path.write_text(
            json.dumps(runtime_obj, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        row["runtime_jui_file"] = str(runtime_path.relative_to(self.run_dir)).replace("\\", "/")

        expected_path, expected_status, names = self._select_expected_jui(case_id)
        if expected_status == "MISSING_EXPECTED" or expected_path is None:
            row["jui_compare_status"] = "MISSING_EXPECTED"
            row["jui_compare_note"] = "No expected .jui file in test folder."
            return
        if expected_status == "AMBIGUOUS_EXPECTED":
            row["jui_compare_status"] = "AMBIGUOUS_EXPECTED"
            row["jui_compare_note"] = "Multiple expected .jui files; cannot auto-pick."
            if names:
                row["expected_jui_candidates"] = names
            return

        row["expected_jui_file"] = str(expected_path.relative_to(self.tests_root.parent.parent)).replace("\\", "/")
        try:
            expected_obj = json.loads(expected_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            row["jui_compare_status"] = "EXPECTED_INVALID"
            row["jui_compare_note"] = f"expected .jui parse error: {exc}"
            return

        expected_sig = canonical_json_string(expected_obj)
        runtime_sig = canonical_json_string(runtime_obj)
        if expected_sig == runtime_sig:
            row["jui_compare_status"] = "MATCH"
            row["jui_compare_note"] = "runtime user_data_dump matches expected .jui."
        else:
            row["jui_compare_status"] = "DIFF"
            row["jui_compare_note"] = "runtime user_data_dump differs from expected .jui."

    def _start_capture_worker(self) -> None:
        if self._capture_thread is not None:
            return
        self._capture_thread = threading.Thread(
            target=self._capture_worker_main,
            name="itnwn-app-capture-worker",
            daemon=True,
        )
        self._capture_thread.start()

    def _set_capture_row_state(
        self,
        case_id: str,
        status: str,
        *,
        error: str = "",
        files: list[str] | None = None,
    ) -> None:
        with self.lock:
            for row in self.results:
                if str(row.get("case_id", "")).strip() != case_id:
                    continue
                row["app_capture_status"] = status
                if error:
                    row["app_capture_error"] = error
                if files is not None:
                    row["app_capture_files"] = files
                break
            self.flush_summary()

    def _copy_capture_files(self, case_id: str, capture_test: str) -> list[str]:
        source_dir = self.tests_root / capture_test
        if not source_dir.exists():
            return []

        target_dir = self.run_dir / "screenshots" / case_id
        target_dir.mkdir(parents=True, exist_ok=True)

        copied: list[str] = []
        for src in sorted(source_dir.glob("app_*.png"), key=lambda p: p.name.lower()):
            dst = target_dir / src.name
            shutil.copy2(src, dst)
            copied.append(str(dst.relative_to(self.run_dir)).replace("\\", "/"))
        return copied

    def _run_capture_job(self, case_id: str, capture_test: str) -> None:
        if not self.capture_script.exists():
            self._set_capture_row_state(case_id, "FAILED", error=f"missing capture script: {self.capture_script}")
            return

        self._set_capture_row_state(case_id, "RUNNING")
        cmd = [
            "powershell",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(self.capture_script),
            "-Test",
            capture_test,
            "-TestsRoot",
            str(self.tests_root),
            "-Port",
            str(self.capture_port),
            "-CaptureOnly",
        ]
        try:
            proc = subprocess.run(
                cmd,
                cwd=str(self.repo_root),
                capture_output=True,
                text=True,
                timeout=900,
                check=False,
            )
        except Exception as exc:
            self._set_capture_row_state(case_id, "FAILED", error=str(exc))
            return

        if proc.returncode != 0:
            tail = (proc.stderr or proc.stdout or "").strip()
            if len(tail) > 800:
                tail = tail[-800:]
            self._set_capture_row_state(
                case_id,
                "FAILED",
                error=f"capture returncode={proc.returncode}; {tail}",
            )
            return

        files = self._copy_capture_files(case_id, capture_test)
        self._set_capture_row_state(case_id, "DONE", files=files)

    def _capture_worker_main(self) -> None:
        while not self._capture_stop.is_set():
            try:
                case_id, capture_test = self._capture_queue.get(timeout=0.5)
            except Empty:
                continue
            try:
                self._run_capture_job(case_id, capture_test)
            finally:
                self._capture_queue.task_done()


class RunnerHttpServer(ThreadingHTTPServer):
    def __init__(self, server_address: tuple[str, int], state: RunnerState):
        super().__init__(server_address, RunnerHandler)
        self.state = state


class RunnerHandler(BaseHTTPRequestHandler):
    server: RunnerHttpServer  # type: ignore[assignment]

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"[{utc_now_iso()}] {self.address_string()} - {fmt % args}")

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        try:
            self.wfile.write(raw)
        except (BrokenPipeError, ConnectionResetError, ssl.SSLError, OSError):
            # NWNX HTTPClient may close/retry aggressively. Treat response write as best-effort.
            return

    def _discard_body(self) -> None:
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0:
            return
        try:
            self.rfile.read(length)
        except (OSError, socket.timeout):
            return

    def _read_json(self) -> dict[str, Any] | None:
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return None
        if length <= 0:
            return None
        body = self.rfile.read(length)
        try:
            parsed = json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None
        return parsed if isinstance(parsed, dict) else None

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]
        state = self.server.state

        if path == "/health":
            self._send_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "service": "itnwn-api-runner",
                    "run_id": state.run_id,
                    "tests_count": len(state.tests),
                },
            )
            return

        if path == "/nui-runner/tests":
            state.mark_started()
            self._send_json(
                HTTPStatus.OK,
                {
                    "run_id": state.run_id,
                    "tests_count": len(state.tests),
                    "tests": state.tests,
                },
            )
            return

        if path == "/nui-runner/tests-mini":
            state.mark_started()
            mini_tests: list[list[Any]] = []
            for t in state.tests:
                mini_tests.append(
                    [
                        str(t.get("case_id", "")),
                        str(t.get("script_resref", "")),
                        str(t.get("expected_window_id", "")),
                        int(t.get("delay_ms", 1200)),
                        str(t.get("capture_test", "")),
                    ]
                )
            self._send_json(
                HTTPStatus.OK,
                {
                    "run_id": state.run_id,
                    "tests_count": len(state.tests),
                    "tests": mini_tests,
                },
            )
            return

        if path == "/nui-runner/summary":
            try:
                payload = json.loads(state.summary_path.read_text(encoding="utf-8"))
            except Exception as exc:  # pragma: no cover - defensive
                self._send_json(HTTPStatus.INTERNAL_SERVER_ERROR, {"ok": False, "error": str(exc)})
                return
            self._send_json(HTTPStatus.OK, payload)
            return

        self._send_json(HTTPStatus.NOT_FOUND, {"ok": False, "error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]
        state = self.server.state

        if path == "/nui-runner/start":
            self._discard_body()
            state.mark_started()
            self._send_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "run_id": state.run_id,
                    "tests_count": len(state.tests),
                },
            )
            return

        if path == "/nui-runner/finish":
            self._discard_body()
            # Return fast ACK to NWNX client.
            # Waiting for screenshot capture here can exceed NWNX HTTPClient timeout
            # and cause false "HTTP failed" on the final request.
            capture_pending = state.capture_pending_count()
            capture_wait_ok = (capture_pending == 0)
            state.mark_finished()
            self._send_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "run_id": state.run_id,
                    "total_results": len(state.results),
                    "capture_wait_ok": capture_wait_ok,
                    "capture_pending": capture_pending,
                },
            )
            return

        if path == "/nui-runner/results":
            parsed = self._read_json()
            if parsed is None:
                self._send_json(HTTPStatus.BAD_REQUEST, {"ok": False, "error": "invalid JSON object payload"})
                return

            index, row = state.add_result(parsed)
            self._send_json(
                HTTPStatus.OK,
                {
                    "ok": True,
                    "run_id": state.run_id,
                    "result_index": index,
                    "case_id": row.get("case_id", ""),
                    "status": row.get("status", ""),
                },
            )
            return

        self._send_json(HTTPStatus.NOT_FOUND, {"ok": False, "error": "not found"})


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="ITNWN API runner server.")
    parser.add_argument("--host", default=read_env_host("127.0.0.1"), help="Bind host (default: 127.0.0.1 or ITNWN_API_HOST).")
    parser.add_argument("--port", type=int, default=read_env_port(51871), help="Bind port (default: 51871 or ITNWN_API_PORT).")
    parser.add_argument(
        "--tls-cert",
        type=Path,
        default=read_env_tls_cert(resolve_default_tls_cert()),
        help="TLS certificate file (.crt/.pem). Required for HTTPS server.",
    )
    parser.add_argument(
        "--tls-key",
        type=Path,
        default=read_env_tls_key(resolve_default_tls_key()),
        help="TLS private key file (.key/.pem). Required for HTTPS server.",
    )
    parser.add_argument("--tests-root", type=Path, default=resolve_default_tests_root(), help="tests/app root path (integration source scripts).")
    parser.add_argument(
        "--nwnscript-dir",
        type=Path,
        default=read_env_nwscript_dir(resolve_default_nwscript_dir()),
        help="Source folder with NWNX include scripts (default: ~/Documents/NWScript or ITNWN_NWSCRIPT_DIR).",
    )
    parser.add_argument(
        "--module-path",
        type=Path,
        default=read_env_module_path(resolve_default_module_path()),
        help="NWN module temp0 path used for auto-sync of .nss (default from HOME or ITNWN_MODULE_PATH).",
    )
    parser.add_argument("--manifest", type=Path, default=resolve_default_manifest(), help="Optional JSON manifest with tests list.")
    parser.add_argument("--use-manifest", action="store_true", help="Use manifest as source of test list instead of auto-discovery from tests/app.")
    parser.add_argument(
        "--artifacts-root",
        type=Path,
        default=resolve_default_artifacts_root(),
        help="Artifacts root for run outputs.",
    )
    parser.add_argument("--run-id", default="", help="Optional custom run id.")
    parser.add_argument("--default-delay-ms", type=int, default=1200, help="Fallback delay_ms for cases.")
    parser.add_argument("--overwrite-run", action="store_true", help="Allow overwriting existing run directory.")
    parser.add_argument("--force-replace-nss", action="store_true", help="Allow overwriting existing .nss in temp0 during startup sync.")
    parser.add_argument("--skip-nss-sync", action="store_true", help="Skip syncing .nss files into temp0 on startup.")
    parser.add_argument("--skip-runner-compile", action="store_true", help="Skip compiling runner scripts to .ncs on startup.")
    parser.add_argument(
        "--disable-app-capture",
        action="store_true",
        help="Disable app screenshot capture on each POST /nui-runner/results.",
    )
    parser.add_argument(
        "--capture-port",
        type=int,
        default=4174,
        help="Builder app capture port used by tests/nwn/_tools capture scripts (default: 4174).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.port < 1 or args.port > 65535:
        raise SystemExit("Port must be in range 1..65535.")

    tests_root = args.tests_root.resolve()
    nwscript_dir = args.nwnscript_dir.resolve()
    module_path = args.module_path.resolve()
    manifest = args.manifest.resolve()
    artifacts_root = args.artifacts_root.resolve()
    tls_cert = args.tls_cert.resolve()
    tls_key = args.tls_key.resolve()
    lock_path = artifacts_root / f"_server_lock_{args.port}.json"

    if not tls_cert.exists():
        raise SystemExit(
            f"TLS cert file not found: {tls_cert}\n"
            "Provide --tls-cert/--tls-key or run start_api_runner.ps1 (it auto-generates local TLS certs)."
        )
    if not tls_key.exists():
        raise SystemExit(
            f"TLS key file not found: {tls_key}\n"
            "Provide --tls-cert/--tls-key or run start_api_runner.ps1 (it auto-generates local TLS certs)."
        )

    run_id = args.run_id.strip() or datetime.now(timezone.utc).strftime("run_%Y%m%d_%H%M%S")
    run_dir = artifacts_root / "runs" / run_id
    try:
        acquire_server_lock(lock_path=lock_path, host=args.host, port=args.port)
    except RuntimeError as exc:
        raise SystemExit(str(exc))
    if run_dir.exists() and not args.overwrite_run:
        raise SystemExit(f"Run dir exists: {run_dir}\nUse --overwrite-run or provide --run-id.")
    if run_dir.exists() and args.overwrite_run:
        shutil.rmtree(run_dir, ignore_errors=True)

    copied_app = 0
    collisions: list[str] = []
    copied_required = 0
    skipped_app = 0
    copied_runner = 0
    runner_collisions: list[str] = []
    skipped_runner = 0
    compiled_runner_ncs = 0
    launchers_written = 0

    try:
        tests, tests_source, launchers_written = load_tests(
            manifest_path=manifest,
            tests_root=tests_root,
            default_delay_ms=args.default_delay_ms,
            use_manifest=args.use_manifest,
        )

        if not args.skip_nss_sync:
            copied_app, collisions, copied_required, skipped_app = deploy_all_nss_with_required_includes(
                source_dir=tests_root,
                module_path=module_path,
                nwscript_dir=nwscript_dir,
                force_replace=args.force_replace_nss,
            )
            runner_nss_files = collect_runner_nss_files()
            copied_runner, runner_collisions, skipped_runner = deploy_extra_nss_files(
                extra_files=runner_nss_files,
                module_path=module_path,
                force_replace=args.force_replace_nss,
            )
            compiled_runner_ncs = compile_runner_ncs(
                module_path=module_path,
                nwscript_dir=nwscript_dir,
                skip_compile=args.skip_runner_compile,
            )
    except (RuntimeError, ValueError) as exc:
        raise SystemExit(str(exc))

    state = RunnerState(
        run_id=run_id,
        tests=tests,
        tests_source=tests_source,
        tests_root=tests_root,
        run_dir=run_dir,
        results_ndjson=run_dir / "results.ndjson",
        summary_path=run_dir / "summary.json",
        tests_snapshot_path=run_dir / "tests_snapshot.json",
        capture_enabled=(not args.disable_app_capture),
        capture_port=args.capture_port,
    )
    state.write_initial_files()

    server = RunnerHttpServer((args.host, args.port), state)
    tls_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    # Compatibility profile for legacy TLS clients (e.g. NWNX HTTP stacks on some setups).
    try:
        tls_context.minimum_version = ssl.TLSVersion.TLSv1
    except Exception:
        pass
    try:
        # Broaden cipher set for local test harness interoperability.
        tls_context.set_ciphers("DEFAULT:@SECLEVEL=0")
    except Exception:
        pass
    try:
        tls_context.load_cert_chain(certfile=str(tls_cert), keyfile=str(tls_key))
    except Exception as exc:
        raise SystemExit(f"Failed to load TLS cert/key:\n- cert: {tls_cert}\n- key: {tls_key}\n- error: {exc}")
    server.socket = tls_context.wrap_socket(server.socket, server_side=True)
    bind_host, bind_port = server.server_address

    print("ITNWN API runner server started")
    print("- scheme: https")
    print(f"- host: {bind_host}")
    print(f"- port: {bind_port}")
    print(f"- tls cert: {tls_cert}")
    print(f"- tls key: {tls_key}")
    print(f"- run_id: {run_id}")
    print(f"- lock file: {lock_path}")
    print(f"- tests source: {tests_source}")
    print(f"- tests count: {len(tests)}")
    print(f"- app capture enabled: {state.capture_enabled}")
    print(f"- app capture port: {state.capture_port}")
    print(f"- module temp0: {module_path}")
    print(f"- nwscript dir: {nwscript_dir}")
    print(f"- nss sync skipped: {args.skip_nss_sync}")
    print(f"- nss synced (tests/app): {copied_app}")
    print(f"- nss unchanged (tests/app): {skipped_app}")
    print(f"- runner nss synced (tests/nwn/api_runner): {copied_runner}")
    print(f"- runner nss unchanged: {skipped_runner}")
    print(f"- runner ncs compile skipped: {args.skip_runner_compile}")
    print(f"- runner ncs compiled: {compiled_runner_ncs}")
    print(f"- nwnx include synced: {copied_required}")
    print(f"- static launchers written/updated: {launchers_written}")
    if collisions:
        print(f"- app nss overwritten: {len(collisions)}")
    if runner_collisions:
        print(f"- runner nss overwritten: {len(runner_collisions)}")
    print(f"- run dir: {run_dir}")
    print("")
    print("Endpoints:")
    print(f"- GET  https://{bind_host}:{bind_port}/health")
    print(f"- GET  https://{bind_host}:{bind_port}/nui-runner/tests")
    print(f"- POST https://{bind_host}:{bind_port}/nui-runner/start")
    print(f"- POST https://{bind_host}:{bind_port}/nui-runner/results")
    print(f"- POST https://{bind_host}:{bind_port}/nui-runner/finish")
    print(f"- GET  https://{bind_host}:{bind_port}/nui-runner/summary")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
