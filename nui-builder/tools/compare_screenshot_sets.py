#!/usr/bin/env python3
"""
Batch comparison for Aurora-vs-app screenshot sets.

Generates:
- summary.json
- summary.csv
- diff images for each compared case

Typical usage:
  python tools/compare_screenshot_sets.py ^
    --reference-dir ..\\tests\\app ^
    --candidate-dir .\\artifacts\\app-screenshots ^
    --output-dir .\\artifacts\\aurora-compare
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageChops, ImageStat
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency: Pillow. Install with `pip install pillow` "
        "or run with bundled Codex runtime Python."
    ) from exc


SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}


@dataclass
class CompareMetrics:
    width: int
    height: int
    mae: float
    rmse: float
    similarity_percent: float
    similarity_percent_rmse: float
    changed_pixels: int
    changed_percent: float
    changed_bbox: tuple[int, int, int, int] | None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Batch compare screenshot sets.")
    parser.add_argument("--reference-dir", type=Path, required=True, help="Directory with Aurora/reference screenshots.")
    parser.add_argument("--candidate-dir", type=Path, required=True, help="Directory with app-render screenshots.")
    parser.add_argument("--output-dir", type=Path, required=True, help="Base output directory for reports and diffs.")
    parser.add_argument(
        "--min-similarity",
        type=float,
        default=97.0,
        help="PASS threshold for similarity_percent (default: 97.0).",
    )
    parser.add_argument(
        "--normalize-size",
        choices=("reference", "none"),
        default="reference",
        help="Resize candidate to reference size before comparison (default: reference).",
    )
    parser.add_argument(
        "--match-mode",
        choices=("relative", "basename"),
        default="relative",
        help="How files are matched between sets (default: relative).",
    )
    parser.add_argument(
        "--fail-on-regressions",
        action="store_true",
        help="Return exit code 1 if any compared case is below min similarity.",
    )
    parser.add_argument(
        "--write-top",
        type=int,
        default=20,
        help="How many worst mismatches to include in highlighted summary (default: 20).",
    )
    return parser.parse_args()


def list_images(root: Path) -> list[Path]:
    if not root.exists():
        return []
    return sorted(
        [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() in SUPPORTED_EXTENSIONS],
        key=lambda p: str(p).lower(),
    )


def to_rgba(path: Path) -> Image.Image:
    with Image.open(path) as img:
        return img.convert("RGBA")


def compare_images(reference: Image.Image, candidate: Image.Image) -> tuple[CompareMetrics, Image.Image]:
    if reference.size != candidate.size:
        raise ValueError(f"Image sizes differ: reference={reference.size}, candidate={candidate.size}")

    diff = ImageChops.difference(reference, candidate)

    means = ImageStat.Stat(diff).mean
    mae = float(sum(means) / len(means))
    similarity_mae = max(0.0, 100.0 * (1.0 - (mae / 255.0)))

    channel_mse: list[float] = []
    pixels = reference.size[0] * reference.size[1]
    for channel in diff.split():
        hist = channel.histogram()
        squared_sum = sum((idx * idx) * count for idx, count in enumerate(hist))
        channel_mse.append(squared_sum / float(pixels))
    mse = sum(channel_mse) / float(len(channel_mse))
    rmse = float(math.sqrt(mse))
    similarity_rmse = max(0.0, 100.0 * (1.0 - (rmse / 255.0)))

    alpha_mask = diff.convert("L").point(lambda px: 255 if px > 0 else 0, mode="L")
    changed_pixels = int(alpha_mask.histogram()[255])
    changed_percent = float(100.0 * (changed_pixels / float(pixels)))
    changed_bbox = alpha_mask.getbbox()

    metrics = CompareMetrics(
        width=reference.size[0],
        height=reference.size[1],
        mae=round(mae, 6),
        rmse=round(rmse, 6),
        similarity_percent=round(similarity_mae, 6),
        similarity_percent_rmse=round(similarity_rmse, 6),
        changed_pixels=changed_pixels,
        changed_percent=round(changed_percent, 6),
        changed_bbox=changed_bbox,
    )
    return metrics, diff


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def as_posix_rel(path: Path, base: Path) -> str:
    return path.relative_to(base).as_posix()


def build_candidate_index(candidate_files: list[Path], base: Path) -> tuple[dict[str, Path], dict[str, list[Path]]]:
    by_relative: dict[str, Path] = {}
    by_basename: dict[str, list[Path]] = {}
    for file_path in candidate_files:
        rel = as_posix_rel(file_path, base)
        by_relative[rel] = file_path
        by_basename.setdefault(file_path.name.lower(), []).append(file_path)
    return by_relative, by_basename


def resolve_candidate(
    ref_file: Path,
    ref_base: Path,
    match_mode: str,
    candidate_by_relative: dict[str, Path],
    candidate_by_basename: dict[str, list[Path]],
) -> tuple[Path | None, str]:
    ref_rel = as_posix_rel(ref_file, ref_base)
    if match_mode == "relative":
        candidate = candidate_by_relative.get(ref_rel)
        return candidate, "relative"

    hits = candidate_by_basename.get(ref_file.name.lower(), [])
    if len(hits) == 1:
        return hits[0], "basename"
    if len(hits) > 1:
        return None, "basename-ambiguous"
    return None, "basename-missing"


def metrics_to_dict(metrics: CompareMetrics) -> dict[str, object]:
    return {
        "width": metrics.width,
        "height": metrics.height,
        "mae": metrics.mae,
        "rmse": metrics.rmse,
        "similarity_percent": metrics.similarity_percent,
        "similarity_percent_rmse": metrics.similarity_percent_rmse,
        "changed_pixels": metrics.changed_pixels,
        "changed_percent": metrics.changed_percent,
        "changed_bbox": list(metrics.changed_bbox) if metrics.changed_bbox else None,
    }


def write_csv(rows: Iterable[dict[str, object]], output_file: Path) -> None:
    rows = list(rows)
    if not rows:
        return
    ensure_parent(output_file)
    fieldnames = [
        "status",
        "reference",
        "candidate",
        "match_method",
        "similarity_percent",
        "similarity_percent_rmse",
        "mae",
        "rmse",
        "changed_percent",
        "changed_pixels",
        "changed_bbox",
        "diff_image",
    ]
    with output_file.open("w", encoding="utf8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in fieldnames})


def main() -> int:
    args = parse_args()
    ref_dir = args.reference_dir.resolve()
    candidate_dir = args.candidate_dir.resolve()
    output_root = args.output_dir.resolve()
    run_stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir = output_root / run_stamp
    diff_dir = run_dir / "diffs"
    diff_dir.mkdir(parents=True, exist_ok=True)

    ref_files = list_images(ref_dir)
    candidate_files = list_images(candidate_dir)

    candidate_by_relative, candidate_by_basename = build_candidate_index(candidate_files, candidate_dir)
    used_candidates: set[Path] = set()

    rows: list[dict[str, object]] = []
    missing: list[dict[str, object]] = []
    compared_count = 0
    regressions = 0

    for ref_file in ref_files:
        candidate_file, match_method = resolve_candidate(
            ref_file,
            ref_dir,
            args.match_mode,
            candidate_by_relative,
            candidate_by_basename,
        )
        ref_rel = as_posix_rel(ref_file, ref_dir)
        if candidate_file is None:
            row = {
                "status": "MISSING_CANDIDATE",
                "reference": ref_rel,
                "candidate": "",
                "match_method": match_method,
                "similarity_percent": "",
                "similarity_percent_rmse": "",
                "mae": "",
                "rmse": "",
                "changed_percent": "",
                "changed_pixels": "",
                "changed_bbox": "",
                "diff_image": "",
            }
            rows.append(row)
            missing.append(row)
            continue

        used_candidates.add(candidate_file)
        cand_rel = as_posix_rel(candidate_file, candidate_dir)

        ref_img = to_rgba(ref_file)
        cand_img = to_rgba(candidate_file)
        if args.normalize_size == "reference" and cand_img.size != ref_img.size:
            cand_img = cand_img.resize(ref_img.size, Image.Resampling.BICUBIC)

        metrics, diff = compare_images(ref_img, cand_img)
        compared_count += 1
        pass_status = metrics.similarity_percent >= args.min_similarity
        if not pass_status:
            regressions += 1

        diff_file = diff_dir / f"{Path(ref_rel).with_suffix('').as_posix().replace('/', '__')}.diff.png"
        ensure_parent(diff_file)
        diff.save(diff_file)

        row = {
            "status": "PASS" if pass_status else "FAIL",
            "reference": ref_rel,
            "candidate": cand_rel,
            "match_method": match_method,
            "similarity_percent": metrics.similarity_percent,
            "similarity_percent_rmse": metrics.similarity_percent_rmse,
            "mae": metrics.mae,
            "rmse": metrics.rmse,
            "changed_percent": metrics.changed_percent,
            "changed_pixels": metrics.changed_pixels,
            "changed_bbox": json.dumps(list(metrics.changed_bbox) if metrics.changed_bbox else None),
            "diff_image": diff_file.relative_to(run_dir).as_posix(),
            "metrics": metrics_to_dict(metrics),
        }
        rows.append(row)

    extra_candidates = [
        as_posix_rel(path, candidate_dir) for path in candidate_files if path not in used_candidates
    ]
    extra_candidates.sort()

    compared_rows = [row for row in rows if row.get("status") in {"PASS", "FAIL"}]
    compared_rows_sorted = sorted(
        compared_rows,
        key=lambda row: float(row["similarity_percent"]),
    )
    worst = compared_rows_sorted[: max(0, int(args.write_top))]

    summary = {
        "generated_at": dt.datetime.now().isoformat(),
        "reference_dir": str(ref_dir),
        "candidate_dir": str(candidate_dir),
        "match_mode": args.match_mode,
        "normalize_size": args.normalize_size,
        "threshold_similarity_percent": args.min_similarity,
        "totals": {
            "reference_images": len(ref_files),
            "candidate_images": len(candidate_files),
            "compared": compared_count,
            "missing_candidates": len(missing),
            "extra_candidates": len(extra_candidates),
            "failures_below_threshold": regressions,
            "passes": max(0, compared_count - regressions),
        },
        "worst_mismatches": [
            {
                "reference": row["reference"],
                "candidate": row["candidate"],
                "similarity_percent": row["similarity_percent"],
                "changed_percent": row["changed_percent"],
                "diff_image": row["diff_image"],
            }
            for row in worst
        ],
        "missing_candidates": [row["reference"] for row in missing],
        "extra_candidates": extra_candidates,
        "results": [
            {
                "status": row["status"],
                "reference": row["reference"],
                "candidate": row["candidate"],
                "match_method": row["match_method"],
                "similarity_percent": row["similarity_percent"],
                "similarity_percent_rmse": row["similarity_percent_rmse"],
                "mae": row["mae"],
                "rmse": row["rmse"],
                "changed_percent": row["changed_percent"],
                "changed_pixels": row["changed_pixels"],
                "changed_bbox": row["changed_bbox"],
                "diff_image": row["diff_image"],
            }
            for row in rows
        ],
    }

    summary_json = run_dir / "summary.json"
    summary_csv = run_dir / "summary.csv"
    ensure_parent(summary_json)
    summary_json.write_text(json.dumps(summary, indent=2), encoding="utf8")
    write_csv(rows, summary_csv)

    print(f"Compared: {compared_count}")
    print(f"Missing candidates: {len(missing)}")
    print(f"Extra candidates: {len(extra_candidates)}")
    print(f"Failures (<{args.min_similarity:.2f}%): {regressions}")
    print(f"Report: {summary_json}")

    if args.fail_on_regressions and regressions > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
