#!/usr/bin/env python3
"""
Auto-detects each cell in a sprite sheet via white-gap analysis, crops each
frame to its bbox, then repacks into a uniform grid. Solves the "looks like
4 frames at the same time" bug caused by slicing assumed grids that don't
match the actual artwork layout.

Run after dropping new source assets into Resources/. Idempotent: rebuilds
from `_resource_originals/` (the pre-strip backup) every run.
"""

from collections import deque
from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
RESOURCES = PROJECT / "ZombieSmasher" / "Resources"
ORIGINALS = PROJECT / "_resource_originals"
REPACKED = PROJECT / "_resource_repacked_originals"

# Sheets to repack with their EXPECTED uniform grid (cols, rows).
# The detector picks the actual cell boundaries; the writer repacks them into
# exactly cols×rows uniform cells. If detected grid doesn't match expected,
# we still repack the first cols×rows detected cells (extras dropped, missing
# left transparent).
SHEETS = [
    # Player movement / idle / actions
    ("Player1IdleBachataDance.png", 4, 3),
    ("Player1TakingDamageSpriteSheet.png", 4, 2),
    ("Player1ShooingBowFireArrowAnimation.png", 4, 2),
    ("Player1SwingingBatSpriteSheet.png", 4, 2),
    ("Player1DeathAnimation.png", 4, 4),
    ("ShootingHandGunSpriteSheet.png", 4, 2),
    ("ShootingRifleAnimation.png", 4, 2),
    ("ShootingBowAnimationSpriteSheet.png", 4, 2),

    # Existing walks (kept the user's original layout)
    ("Player1WalkingWithHandGunEquiped.png", 4, 3),
    ("WalkingWithRifleSpriteAnimation.png", 4, 2),
    ("Player1WalkingwithBow.png", 4, 2),
    ("Player1WalkingAnimationUnequiped.png", 6, 1),
    ("Player1RunningSpriteSheetAnimation.png", 4, 2),
    ("Player1JumpingAnimationSpriteSheet.png", 4, 2),

    # Projectiles — repack just the first 4 frames as a clean loop
    ("HandGunBulletTravelingAnimationSpriteSheet.png", 4, 1),
    ("TravelingRifleBulletSpriteSheet.png", 4, 1),
    ("FlyingArrowBurningFireSpriteSheet.png", 4, 1),
    ("RegularArrowProjectileSpriteSheet.png", 4, 1),

    # Zombie
    ("ZombieWalkingAnimations.png", 4, 3),
    ("ZombieBitingAttackAnimation.png", 4, 3),
    ("ZombieDyingByBeingShotDeathSpriteSheet.png", 4, 3),
    ("ZombieDeathByFireArrowAnimation.png", 4, 4),
    ("ZombieDeathByNormalArrowSpriteSheet.png", 4, 3),
    ("ZombieDeathByGrenadeSpriteSheet.png", 4, 3),
    ("ZombieTakingBulletDamageSpriteSheet.png", 4, 3),
    ("ZombieTakingDamageByFireArrow.png", 4, 3),
]


def strip_white(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA").copy()
    W, H = img.size
    px = img.load()

    def is_white(p):
        return p[0] >= 230 and p[1] >= 230 and p[2] >= 230

    visited = [[False] * H for _ in range(W)]
    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if is_white(px[x, y]):
                q.append((x, y)); visited[x][y] = True
    for y in range(H):
        for x in (0, W - 1):
            if is_white(px[x, y]) and not visited[x][y]:
                q.append((x, y)); visited[x][y] = True
    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and not visited[nx][ny] and is_white(px[nx, ny]):
                visited[nx][ny] = True; q.append((nx, ny))
    return img


def detect_dividers(img: Image.Image):
    W, H = img.size
    px = img.load()
    trans_row = [sum(1 for x in range(W) if px[x, y][3] == 0) for y in range(H)]
    trans_col = [sum(1 for y in range(H) if px[x, y][3] == 0) for x in range(W)]

    def runs(arr, threshold_ratio=0.95, min_run=3):
        cutoff = max(arr) * threshold_ratio
        out = []; cur = []
        for i, v in enumerate(arr):
            if v >= cutoff:
                cur.append(i)
            else:
                if len(cur) >= min_run: out.append((cur[0], cur[-1]))
                cur = []
        if len(cur) >= min_run: out.append((cur[0], cur[-1]))
        return out

    rgaps = runs(trans_row)
    cgaps = runs(trans_col)

    def boundaries(gaps, total):
        internal = list(gaps)
        start, end = 0, total
        if internal and internal[0][0] == 0:
            start = internal[0][1] + 1
            internal = internal[1:]
        if internal and internal[-1][1] == total - 1:
            end = internal[-1][0]
            internal = internal[:-1]
        return [start] + [(g[0] + g[1]) // 2 for g in internal] + [end]

    return boundaries(rgaps, H), boundaries(cgaps, W)


def repack(src_path: Path, expected_cols: int, expected_rows: int,
           pad: int = 30) -> Image.Image:
    src = Image.open(src_path).convert("RGBA")
    stripped = strip_white(src)
    row_bounds, col_bounds = detect_dividers(stripped)
    detected_rows = len(row_bounds) - 1
    detected_cols = len(col_bounds) - 1

    print(f"  detected {detected_cols}x{detected_rows}, expected {expected_cols}x{expected_rows}")

    # Crop each detected cell to its content bbox
    frames = []
    rows_to_use = min(detected_rows, expected_rows)
    cols_to_use = min(detected_cols, expected_cols)
    for r in range(rows_to_use):
        for c in range(cols_to_use):
            box = (col_bounds[c], row_bounds[r],
                   col_bounds[c + 1], row_bounds[r + 1])
            cell = stripped.crop(box)
            bbox = cell.getbbox()
            if bbox is None:
                trimmed = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
            else:
                trimmed = cell.crop(bbox)
            frames.append(trimmed)

    # Pad to fill expected grid (transparent fillers)
    while len(frames) < expected_cols * expected_rows:
        frames.append(Image.new("RGBA", (1, 1), (0, 0, 0, 0)))

    # Compute uniform cell size (largest content + padding)
    max_w = max(f.size[0] for f in frames) if frames else 1
    max_h = max(f.size[1] for f in frames) if frames else 1
    cw = max_w + pad * 2
    ch = max_h + pad * 2

    # Re-pack with each frame BOTTOM-CENTERED (feet alignment) so feet are
    # consistent across frames in the new uniform grid.
    out = Image.new("RGBA", (cw * expected_cols, ch * expected_rows), (0, 0, 0, 0))
    for i in range(expected_cols * expected_rows):
        if i >= len(frames):
            break
        f = frames[i]
        r, c = divmod(i, expected_cols)
        x = c * cw + (cw - f.size[0]) // 2
        # bottom-align: paste with bottom of f at (r+1)*ch - pad
        y = (r + 1) * ch - pad - f.size[1]
        out.paste(f, (x, y), f)
    return out


def main():
    REPACKED.mkdir(exist_ok=True)
    for name, cols, rows in SHEETS:
        src_in_resources = RESOURCES / name
        original_backup = ORIGINALS / name
        if not original_backup.exists() and src_in_resources.exists():
            original_backup.write_bytes(src_in_resources.read_bytes())
        if not original_backup.exists():
            print(f"missing  {name}")
            continue
        # Always rebuild from the original (pre-strip pre-pack)
        print(f"repack   {name} ({cols}x{rows})")
        repacked = repack(original_backup, cols, rows)
        repacked.save(src_in_resources, "PNG")
        # Save a copy in REPACKED for inspection
        repacked.save(REPACKED / name, "PNG")
    print("done")


if __name__ == "__main__":
    main()
