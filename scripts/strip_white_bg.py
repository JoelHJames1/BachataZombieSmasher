#!/usr/bin/env python3
"""
Removes the white background from sprite-sheet PNGs by flood-filling from the
edges. Pixels reachable from any edge that are near-white become transparent;
interior whites (teeth, eyes, highlights) are preserved.

Skips level/menu background images, which are meant to be opaque scenery.
Originals are backed up to Resources/_originals/ on first run.
"""

from collections import deque
from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
RESOURCES = PROJECT / "ZombieSmasher" / "Resources"
BACKUP = PROJECT / "_resource_originals"

SKIP = {
    "Level1.png", "Level2.png", "Level3.png", "Level4.png", "Level5.png",
    "MainMenuBackground.png", "road.png",
}

THRESHOLD = 230  # R,G,B all >= this counts as "white-ish"


def is_whiteish(px):
    return px[0] >= THRESHOLD and px[1] >= THRESHOLD and px[2] >= THRESHOLD


def strip(path: Path):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()

    visited = [[False] * h for _ in range(w)]
    q = deque()

    for x in range(w):
        for y in (0, h - 1):
            if is_whiteish(px[x, y]):
                q.append((x, y))
                visited[x][y] = True
    for y in range(h):
        for x in (0, w - 1):
            if is_whiteish(px[x, y]) and not visited[x][y]:
                q.append((x, y))
                visited[x][y] = True

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                if is_whiteish(px[nx, ny]):
                    visited[nx][ny] = True
                    q.append((nx, ny))

    img.save(path, "PNG")


def main():
    BACKUP.mkdir(exist_ok=True)
    for p in sorted(RESOURCES.glob("*.png")):
        if p.name in SKIP:
            print(f"skip   {p.name}")
            continue
        backup = BACKUP / p.name
        if not backup.exists():
            backup.write_bytes(p.read_bytes())
        print(f"strip  {p.name}")
        strip(p)
    print("done")


if __name__ == "__main__":
    main()
