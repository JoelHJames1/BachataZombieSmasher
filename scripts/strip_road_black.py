#!/usr/bin/env python3
"""
Removes the black border at the top of road.png by making any near-black
pixel reachable from the image edge transparent. Mirrors strip_white_bg.py
but flips the threshold for dark instead of light.
"""

from collections import deque
from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
RESOURCES = PROJECT / "ZombieSmasher" / "Resources"
ORIGINALS = PROJECT / "_resource_originals"

THRESHOLD = 25  # rgb max value considered "black"


def is_black(p):
    return p[0] <= THRESHOLD and p[1] <= THRESHOLD and p[2] <= THRESHOLD


def strip_road():
    src = RESOURCES / "road.png"
    backup = ORIGINALS / "road.png"
    if not backup.exists():
        backup.write_bytes(src.read_bytes())
    img = Image.open(backup).convert("RGBA")
    W, H = img.size
    px = img.load()

    visited = [[False] * H for _ in range(W)]
    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if is_black(px[x, y]):
                q.append((x, y)); visited[x][y] = True
    for y in range(H):
        for x in (0, W - 1):
            if is_black(px[x, y]) and not visited[x][y]:
                q.append((x, y)); visited[x][y] = True

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and not visited[nx][ny] and is_black(px[nx, ny]):
                visited[nx][ny] = True
                q.append((nx, ny))

    img.save(src, "PNG")
    print(f"stripped black border from road.png")


if __name__ == "__main__":
    strip_road()
