#!/usr/bin/env python3
"""
Re-centers the visible content of each cell in an animated sprite sheet so the
artwork sits at a consistent anchor across frames. Required when the source
sheet has the subject drawn at different positions per cell, which makes the
animation appear to "jump" in-place.

Operates on already-transparent PNGs (run strip_white_bg.py first).
"""

from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
RESOURCES = PROJECT / "ZombieSmasher" / "Resources"
BACKUP = PROJECT / "_resource_centered_originals"

# (filename, cols, rows)
SHEETS = [
    ("StartButtonAnimationMenuSpriteSheet.png", 4, 2),
    ("MainLogoBachataAnimatonSpriteSheet.png", 4, 3),
    ("MaleCharacterMovementSpriteSheet.png", 4, 3),
    ("IdleBachataDance.png", 4, 3),
    ("WalkingWithHandGunEquiped.png", 4, 3),
    ("WalkingWithRifleSpriteAnimation.png", 4, 3),
    ("WalkingwithBow.png", 4, 3),
]


def centroid(cell):
    """Alpha-weighted center of mass of a cell. Returns (cx, cy) or None."""
    px = cell.load()
    cw, ch = cell.size
    sx = sy = sw = 0
    for y in range(ch):
        for x in range(cw):
            a = px[x, y][3]
            if a:
                sx += x * a
                sy += y * a
                sw += a
    if sw == 0:
        return None
    return sx / sw, sy / sw


def center_sheet(path: Path, cols: int, rows: int):
    img = Image.open(path).convert("RGBA")
    W, H = img.size
    cw, ch = W // cols, H // rows

    cells = []
    centroids = []
    for r in range(rows):
        for c in range(cols):
            cell = img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
            cells.append(cell)
            centroids.append(centroid(cell))

    valid = [c for c in centroids if c is not None]
    if not valid:
        return
    target_cx = sum(p[0] for p in valid) / len(valid)
    target_cy = sum(p[1] for p in valid) / len(valid)

    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        cen = centroids[i]
        if cen is None:
            continue
        dx = int(round(target_cx - cen[0]))
        dy = int(round(target_cy - cen[1]))
        r, c = divmod(i, cols)
        shifted = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        shifted.paste(cell, (dx, dy), cell)
        out.paste(shifted, (c * cw, r * ch), shifted)

    out.save(path, "PNG")


def main():
    BACKUP.mkdir(exist_ok=True)
    for name, cols, rows in SHEETS:
        p = RESOURCES / name
        backup = BACKUP / name
        if not backup.exists():
            backup.write_bytes(p.read_bytes())
        print(f"center {name} ({cols}x{rows})")
        center_sheet(p, cols, rows)
    print("done")


if __name__ == "__main__":
    main()
