#!/usr/bin/env python3
"""
Aggressive whitespace removal for the menu logo: strips every white-ish pixel
to fully transparent (no flood-fill — interior whites go too). For logos where
white isn't part of the design.
"""

from pathlib import Path
from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
LOGO = PROJECT / "ZombieSmasher" / "Resources" / "ZombieSmasherMenuLogo.png"
THRESHOLD = 220


def main():
    img = Image.open(LOGO).convert("RGBA")
    px = img.load()
    W, H = img.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r >= THRESHOLD and g >= THRESHOLD and b >= THRESHOLD:
                px[x, y] = (0, 0, 0, 0)
    img.save(LOGO, "PNG")
    print(f"stripped {LOGO.name}")


if __name__ == "__main__":
    main()
