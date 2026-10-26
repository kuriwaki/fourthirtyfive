# Written by Codex
"""Generate Congress-start-year badges from tracked bundled datasets."""

import argparse
from html import escape
from pathlib import Path
import re
import subprocess


FAMILIES = {
    "dotmaps": ("dotmaps", "shp_dot_"),
    "hexmaps": ("hexmaps", "shp_hex_"),
    "names": ("district names", "info_"),
}


def years_for_files(filenames, prefix):
    """Read years only from the named family's top-level package data files."""
    pattern = re.compile(r"data/" + re.escape(prefix) + r"([0-9]{4})\.rda")
    return sorted({
        int(match.group(1))
        for filename in filenames
        if (match := pattern.fullmatch(filename))
    })


def format_years(years):
    """Condense consecutive Congress start years while preserving gaps."""
    ordered = sorted(set(years))
    if not ordered:
        return "none"

    runs = []
    start = previous = ordered[0]
    for year in ordered[1:]:
        if year != previous + 2:
            runs.append((start, previous))
            start = year
        previous = year
    runs.append((start, previous))
    return ", ".join(
        str(start) if start == end else f"{start}-{end}"
        for start, end in runs
    )


def badge_svg(label, message, color="#007ec6"):
    """Create a small, accessible SVG without a badge-service dependency."""
    label_width = len(label) * 7 + 20
    message_width = len(message) * 7 + 20
    width = label_width + message_width
    title = escape(f"{label}: {message}", quote=True)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="20" role="img" aria-label="{title}">
  <title>{title}</title>
  <clipPath id="badge"><rect width="{width}" height="20" rx="3"/></clipPath>
  <g clip-path="url(#badge)">
    <rect width="{label_width}" height="20" fill="#555"/>
    <rect x="{label_width}" width="{message_width}" height="20" fill="{escape(color, quote=True)}"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,DejaVu Sans,sans-serif" font-size="11">
    <text x="{label_width / 2}" y="14">{escape(label)}</text>
    <text x="{label_width + message_width / 2}" y="14">{escape(message)}</text>
  </g>
</svg>
'''


def write_badges(filenames, output_dir):
    """Write one badge per product; leave unchanged images untouched."""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    for name, (label, prefix) in FAMILIES.items():
        message = format_years(years_for_files(filenames, prefix))
        svg = badge_svg(label, message)
        output_path = output_dir / f"{name}.svg"
        if not output_path.exists() or output_path.read_text(encoding="utf-8") != svg:
            output_path.write_text(svg, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repository", type=Path, default=Path(__file__).resolve().parents[2]
    )
    parser.add_argument("--ref", default="HEAD", help="Git revision to inspect")
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    result = subprocess.run(
        ["git", "ls-tree", "-r", "--name-only", args.ref, "--", "data"],
        cwd=args.repository, check=True, capture_output=True, text=True,
    )
    write_badges(result.stdout.splitlines(), args.output_dir)


if __name__ == "__main__":
    main()
