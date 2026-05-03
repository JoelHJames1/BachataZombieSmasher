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
# (filename, cols, rows, align) — align: "feet" (default) or "center"
SHEETS = [
    # Player movement / idle / actions
    ("Player1IdleBachataDance.png", 4, 3, "feet"),
    ("Player1TakingDamageSpriteSheet.png", 4, 2, "feet"),
    ("Player1FireDamageSpriteSheet.png", 4, 3, "feet"),
    ("Player1ShooingBowFireArrowAnimation.png", 4, 2, "feet"),
    ("Player1SwingingBatSpriteSheet.png", 4, 2, "feet"),
    ("Player1DeathAnimation.png", 4, 4, "feet"),
    ("ShootingHandGunSpriteSheet.png", 4, 2, "feet"),
    ("ShootingRifleAnimation.png", 4, 2, "feet"),
    ("ShootingBowAnimationSpriteSheet.png", 4, 2, "feet"),

    # Existing walks (kept the user's original layout)
    ("Player1WalkingWithHandGunEquiped.png", 4, 3, "feet"),
    ("WalkingWithRifleSpriteAnimation.png", 4, 2, "feet"),
    ("Player1WalkingwithBow.png", 4, 2, "feet"),
    ("Player1WalkingAnimationUnequiped.png", 6, 1, "feet"),
    ("Player1RunningSpriteSheetAnimation.png", 4, 2, "feet"),
    ("Player1JumpingAnimationSpriteSheet.png", 4, 2, "feet"),

    # Projectiles — center-aligned (no fixed bottom anchor)
    ("HandGunBulletTravelingAnimationSpriteSheet.png", 4, 1, "center"),
    ("TravelingRifleBulletSpriteSheet.png", 4, 1, "center"),
    ("FlyingArrowBurningFireSpriteSheet.png", 4, 1, "center"),
    ("RegularArrowProjectileSpriteSheet.png", 4, 1, "center"),

    # Explosion — center-aligned (expands radially). Strict min_gap=40 stops
    # the semi-transparent fading edges from getting picked up as phantom
    # cell dividers.
    ("GrenadeExplosionSpriteSheet.png", 4, 3, "center", 40),

    # Zombie
    ("ZombieWalkingAnimations.png", 4, 3, "feet"),
    ("ZombieBitingAttackAnimation.png", 4, 3, "feet"),
    ("ZombieDyingByBeingShotDeathSpriteSheet.png", 4, 3, "feet"),
    ("ZombieDeathByFireArrowAnimation.png", 4, 4, "feet"),
    ("ZombieDeathByNormalArrowSpriteSheet.png", 4, 3, "feet"),
    ("ZombieDeathByGrenadeSpriteSheet.png", 4, 3, "feet"),
    ("ZombieTakingBulletDamageSpriteSheet.png", 4, 3, "feet"),
    ("ZombieTakingDamageByFireArrow.png", 4, 3, "feet"),

    # Gargoyle (flying enemy) — center-aligned since it flies (no fixed feet).
    ("FlyingGargoleFlyingAnimation.png", 4, 3, "center"),
    ("FlyingGargoleFireAttackSpriteSheetAnimation.png", 4, 3, "center"),
    ("DeadGargoleCrashingDownAnimation.png", 4, 3, "center"),
    ("GargoleFlyingHitByGranadeAnimation.png", 4, 3, "center"),
    ("GargoleFireBallAnimation.png", 4, 3, "center"),
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


def detect_dividers(img: Image.Image, min_gap: int = 3):
    W, H = img.size
    px = img.load()
    trans_row = [sum(1 for x in range(W) if px[x, y][3] == 0) for y in range(H)]
    trans_col = [sum(1 for y in range(H) if px[x, y][3] == 0) for x in range(W)]

    def runs(arr, threshold_ratio=0.95, min_run=min_gap):
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
           align: str = "feet", pad: int = 30, min_gap: int = 3) -> Image.Image:
    src = Image.open(src_path).convert("RGBA")
    stripped = strip_white(src)
    row_bounds, col_bounds = detect_dividers(stripped, min_gap=min_gap)
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

    # Re-pack each frame in its uniform cell. "feet" mode bottom-aligns
    # (used for characters); "center" mode centers vertically (used for
    # projectiles + radial explosion).
    out = Image.new("RGBA", (cw * expected_cols, ch * expected_rows), (0, 0, 0, 0))
    for i in range(expected_cols * expected_rows):
        if i >= len(frames):
            break
        f = frames[i]
        r, c = divmod(i, expected_cols)
        x = c * cw + (cw - f.size[0]) // 2
        if align == "center":
            y = r * ch + (ch - f.size[1]) // 2
        else:
            # feet: bottom of frame at (r+1)*ch - pad
            y = (r + 1) * ch - pad - f.size[1]
        out.paste(f, (x, y), f)
    return out


def main():
    REPACKED.mkdir(exist_ok=True)
    for entry in SHEETS:
        min_gap = 3
        if len(entry) == 5:
            name, cols, rows, align, min_gap = entry  # type: ignore
        elif len(entry) == 4:
            name, cols, rows, align = entry
        else:
            name, cols, rows = entry  # type: ignore
            align = "feet"
        src_in_resources = RESOURCES / name
        original_backup = ORIGINALS / name
        if not original_backup.exists() and src_in_resources.exists():
            original_backup.write_bytes(src_in_resources.read_bytes())
        if not original_backup.exists():
            print(f"missing  {name}")
            continue
        # Always rebuild from the original (pre-strip pre-pack)
        print(f"repack   {name} ({cols}x{rows}, {align}, min_gap={min_gap})")
        repacked = repack(original_backup, cols, rows, align=align, min_gap=min_gap)
        repacked.save(src_in_resources, "PNG")
        # Save a copy in REPACKED for inspection
        repacked.save(REPACKED / name, "PNG")
    print("done")


if __name__ == "__main__":
    main()
