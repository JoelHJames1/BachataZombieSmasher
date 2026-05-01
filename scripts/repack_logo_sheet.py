#!/usr/bin/env python3
"""
Re-packs a non-uniform sprite sheet into a clean grid.
Detects frame bounding boxes by scanning for transparent gaps (rows/cols that
are mostly transparent in the stripped image), crops each frame, then pastes
all frames centered into uniform cells.
"""

from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
SRC = PROJECT / "ZombieSmasher" / "Resources" / "MainLogoBachataAnimatonSpriteSheet.png"
BACKUP = PROJECT / "_resource_centered_originals" / "MainLogoBachataAnimatonSpriteSheet.png"

EXPECTED_COLS = 4
EXPECTED_ROWS = 3


def find_gaps(values, threshold_ratio=0.95, min_run=3):
    """Find runs of indices where values[i] >= threshold_ratio * max(values)."""
    if not values:
        return []
    cutoff = max(values) * threshold_ratio
    runs = []
    cur = []
    for i, v in enumerate(values):
        if v >= cutoff:
            cur.append(i)
        else:
            if len(cur) >= min_run:
                runs.append((cur[0], cur[-1]))
            cur = []
    if len(cur) >= min_run:
        runs.append((cur[0], cur[-1]))
    return runs


def main():
    if BACKUP.exists():
        SRC.write_bytes(BACKUP.read_bytes())
    img = Image.open(SRC).convert("RGBA")
    W, H = img.size
    px = img.load()

    transparent_per_row = [sum(1 for x in range(W) if px[x, y][3] == 0) for y in range(H)]
    transparent_per_col = [sum(1 for y in range(H) if px[x, y][3] == 0) for x in range(W)]

    row_gaps = find_gaps(transparent_per_row)
    col_gaps = find_gaps(transparent_per_col)

    print(f"row gaps: {row_gaps}")
    print(f"col gaps: {col_gaps}")

    def cell_bounds(gaps, total):
        internal = list(gaps)
        start = 0
        end = total
        if internal and internal[0][0] == 0:
            start = internal[0][1] + 1
            internal = internal[1:]
        if internal and internal[-1][1] == total - 1:
            end = internal[-1][0]
            internal = internal[:-1]
        return [start] + [(g[0] + g[1]) // 2 for g in internal] + [end]

    row_bounds = cell_bounds(row_gaps, H)
    col_bounds = cell_bounds(col_gaps, W)

    print(f"row bounds: {row_bounds}")
    print(f"col bounds: {col_bounds}")

    rows = len(row_bounds) - 1
    cols = len(col_bounds) - 1
    print(f"detected grid: {cols}x{rows}")

    if cols != EXPECTED_COLS or rows != EXPECTED_ROWS:
        print(f"WARN: detected grid {cols}x{rows} doesn't match expected {EXPECTED_COLS}x{EXPECTED_ROWS}")

    frames = []
    max_w = max_h = 0
    for r in range(rows):
        for c in range(cols):
            box = (col_bounds[c], row_bounds[r], col_bounds[c + 1], row_bounds[r + 1])
            cell = img.crop(box)
            bbox = cell.getbbox()
            if bbox is None:
                trimmed = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
            else:
                trimmed = cell.crop(bbox)
            frames.append(trimmed)
            max_w = max(max_w, trimmed.size[0])
            max_h = max(max_h, trimmed.size[1])

    pad = 30
    cw = max_w + pad * 2
    ch = max_h + pad * 2
    print(f"frame count: {len(frames)}, max content {max_w}x{max_h}, padded cell {cw}x{ch}")

    out = Image.new("RGBA", (cw * cols, ch * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        r, c = divmod(i, cols)
        x = c * cw + (cw - f.size[0]) // 2
        y = r * ch + (ch - f.size[1]) // 2
        out.paste(f, (x, y), f)

    out.save(SRC, "PNG")
    print(f"wrote uniform {cols}x{rows} sheet, total {out.size}")


if __name__ == "__main__":
    main()
