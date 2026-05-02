#!/usr/bin/env python3
"""
Aligns each cell in an animated sprite sheet so the subject sits at the same
on-screen position across frames.

Two alignment modes:
  - "feet": align by bbox bottom-center (use for characters/zombies whose feet
    should stay planted). Eliminates the "double frame" jitter caused by pose
    changes shifting the centroid.
  - "centroid": align by alpha-weighted center of mass (use for spinning
    pickups, projectiles, explosions where there's no fixed anchor).

Run after strip_white_bg.py.
"""

from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
RESOURCES = PROJECT / "ZombieSmasher" / "Resources"
BACKUP = PROJECT / "_resource_centered_originals"

# Note: character/zombie animation sheets are processed by `repack_all_sheets.py`
# (which detects the actual cell grid + feet-aligns during repack). Listing them
# here would re-center stale backups and undo the repack.

# (filename, cols, rows, mode) — mode: "feet" or "centroid"
SHEETS = [
    # Menu (locked — centroid keeps the logo on the same anchor)
    ("StartButtonAnimationMenuSpriteSheet.png", 4, 2, "centroid"),
    ("MainLogoBachataAnimatonSpriteSheet.png", 4, 3, "centroid"),

    # Spinning pickups — centroid
    ("PickupHandGunSpriteSheet.png", 4, 4, "centroid"),
    ("PickupRifleAmmoBoxSpriteSheet.png", 4, 4, "centroid"),
    ("PickupArrowBagSpriteSheet.png", 4, 4, "centroid"),
    ("PickupFireArrowBagSpriteSheet.png", 4, 4, "centroid"),

    # Projectiles are handled by repack_all_sheets.py — do NOT re-center here.

    # Explosion — centroid (it expands radially)
    ("GrenadeExplosionSpriteSheet.png", 4, 3, "centroid"),
]


def centroid(cell):
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


def feet_anchor(cell):
    """Bottom-center of the visible bbox — anchor that should stay planted."""
    bbox = cell.getbbox()
    if bbox is None:
        return None
    cx = (bbox[0] + bbox[2]) / 2.0
    cy = float(bbox[3])  # bottom of content
    return cx, cy


def center_sheet(path: Path, cols: int, rows: int, mode: str):
    img = Image.open(path).convert("RGBA")
    W, H = img.size
    cw, ch = W // cols, H // rows

    cells = []
    anchors = []
    for r in range(rows):
        for c in range(cols):
            cell = img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
            cells.append(cell)
            if mode == "feet":
                anchors.append(feet_anchor(cell))
            else:
                anchors.append(centroid(cell))

    valid = [a for a in anchors if a is not None]
    if not valid:
        return
    target_x = sum(a[0] for a in valid) / len(valid)
    target_y = sum(a[1] for a in valid) / len(valid)

    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        a = anchors[i]
        if a is None:
            continue
        dx = int(round(target_x - a[0]))
        dy = int(round(target_y - a[1]))
        r, c = divmod(i, cols)
        shifted = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        shifted.paste(cell, (dx, dy), cell)
        out.paste(shifted, (c * cw, r * ch), shifted)

    out.save(path, "PNG")


def main():
    BACKUP.mkdir(exist_ok=True)
    for name, cols, rows, mode in SHEETS:
        p = RESOURCES / name
        if not p.exists():
            print(f"missing {name}")
            continue
        backup = BACKUP / name
        if not backup.exists():
            backup.write_bytes(p.read_bytes())
        else:
            p.write_bytes(backup.read_bytes())
        print(f"{mode:8s} {name} ({cols}x{rows})")
        center_sheet(p, cols, rows, mode)
    print("done")


if __name__ == "__main__":
    main()
