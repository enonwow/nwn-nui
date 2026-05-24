#!/usr/bin/env python3
"""
Simple image similarity checker for NUI visual-regression workflows.

Outputs:
- similarity_percent (0..100)
- mae (mean absolute error 0..255)
- rmse (root mean square error 0..255)
- changed_pixels / changed_percent

Usage:
  python tools/image_similarity.py ref.png cand.png
  python tools/image_similarity.py ref.png cand.png --diff-out diff.png --json
  python tools/image_similarity.py ref.png cand.png --min-similarity 97
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageStat
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency: Pillow. Install with `pip install pillow` "
        "or run this script with the bundled runtime that already has Pillow."
    ) from exc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compare two images and report similarity metrics.")
    parser.add_argument("reference", type=Path, help="Reference image path")
    parser.add_argument("candidate", type=Path, help="Candidate image path")
    parser.add_argument(
        "--normalize-size",
        choices=("reference", "none"),
        default="reference",
        help="Resize candidate to reference size before comparison (default: reference).",
    )
    parser.add_argument("--diff-out", type=Path, default=None, help="Optional diff image output path (PNG/JPG).")
    parser.add_argument(
        "--min-similarity",
        type=float,
        default=None,
        help="Optional threshold. Exit code is 1 when similarity_percent is below this value.",
    )
    parser.add_argument("--json", action="store_true", help="Emit metrics as JSON.")
    return parser.parse_args()


def to_rgba(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(f"Image not found: {path}")
    with Image.open(path) as img:
        return img.convert("RGBA")


def compare_images(reference: Image.Image, candidate: Image.Image) -> dict[str, float | int]:
    if reference.size != candidate.size:
        raise ValueError(f"Image sizes differ: reference={reference.size}, candidate={candidate.size}")

    diff = ImageChops.difference(reference, candidate)

    # MAE over channels
    means = ImageStat.Stat(diff).mean
    mae = sum(means) / len(means)
    similarity_mae = max(0.0, 100.0 * (1.0 - (mae / 255.0)))

    # RMSE over channels using histograms
    channel_mse: list[float] = []
    pixels = reference.size[0] * reference.size[1]
    for channel in diff.split():
        hist = channel.histogram()
        squared_sum = sum((idx * idx) * count for idx, count in enumerate(hist))
        channel_mse.append(squared_sum / float(pixels))
    mse = sum(channel_mse) / float(len(channel_mse))
    rmse = math.sqrt(mse)
    similarity_rmse = max(0.0, 100.0 * (1.0 - (rmse / 255.0)))

    # Any changed pixel across RGBA
    alpha_mask = diff.convert("L").point(lambda px: 255 if px > 0 else 0, mode="L")
    changed_pixels = alpha_mask.histogram()[255]
    changed_percent = 100.0 * (changed_pixels / float(pixels))

    return {
        "width": reference.size[0],
        "height": reference.size[1],
        "mae": round(mae, 6),
        "rmse": round(rmse, 6),
        "similarity_percent": round(similarity_mae, 6),
        "similarity_percent_rmse": round(similarity_rmse, 6),
        "changed_pixels": int(changed_pixels),
        "changed_percent": round(changed_percent, 6),
    }


def main() -> int:
    args = parse_args()
    ref = to_rgba(args.reference)
    cand = to_rgba(args.candidate)

    if args.normalize_size == "reference" and cand.size != ref.size:
        cand = cand.resize(ref.size, Image.Resampling.BICUBIC)

    metrics = compare_images(ref, cand)

    if args.diff_out is not None:
        diff_img = ImageChops.difference(ref, cand)
        args.diff_out.parent.mkdir(parents=True, exist_ok=True)
        diff_img.save(args.diff_out)

    if args.json:
        print(json.dumps(metrics, indent=2))
    else:
        print(f"similarity_percent: {metrics['similarity_percent']:.4f}")
        print(f"similarity_percent_rmse: {metrics['similarity_percent_rmse']:.4f}")
        print(f"mae: {metrics['mae']:.6f}")
        print(f"rmse: {metrics['rmse']:.6f}")
        print(f"changed_pixels: {metrics['changed_pixels']}")
        print(f"changed_percent: {metrics['changed_percent']:.6f}")

    if args.min_similarity is not None and float(metrics["similarity_percent"]) < args.min_similarity:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
