"""Robust board reader: samples several points per tile, ignores hint-yellow
(bright yellow with blue<40) and white hint borders, returns the majority tile color.
"""
import sys
from collections import Counter
import uiautomator2 as u2

SERIAL = "ytjjkbi7bucyjzyl"
OX, OY, TS, W, H = 115, 575, 110, 7, 8
NAMES = {0: ".", 1: "R", 2: "B", 3: "G", 4: "Y", 5: "P", 6: "O"}


def classify(p):
    r, g, b = p[0], p[1], p[2]
    # Ignore hint overlay: bright yellow w/ very low blue, or near-white border.
    if r > 230 and g > 190 and b < 45:
        return -1  # hint arrow/outline -> ignore
    if r > 230 and g > 230 and b > 230:
        return -1  # white hint border -> ignore
    if max(r, g, b) - min(r, g, b) < 35:
        return 0
    if r > 180 and g < 140 and b < 140: return 1
    if b > 150 and r < 150: return 2
    if g > 150 and r < 160 and b < 160: return 3
    if r > 210 and g > 160 and 45 <= b < 120: return 4
    if r > 140 and b > 170 and g < 150: return 5
    if r > 210 and g > 120 and b < 110: return 6
    return 0


def read(d):
    px = d.screenshot().load()
    grid = []
    for y in range(H):
        row = []
        for x in range(W):
            cx, cy = OX + x * TS, OY + y * TS
            votes = Counter()
            for ox, oy in ((0, 0), (-28, -28), (28, -28), (-28, 28), (28, 28)):
                c = classify(px[cx + ox, cy + oy])
                if c >= 0:
                    votes[c] += 1
            row.append(votes.most_common(1)[0][0] if votes else 0)
        grid.append(row)
    return grid


def main():
    d = u2.connect(SERIAL)
    g = read(d)
    print("    " + " ".join(f"c{c}" for c in range(W)))
    for y in range(H):
        print(f"r{y}  " + "  ".join(NAMES[g[y][x]] for x in range(W)))
    print("GRID=" + "/".join("".join(NAMES[g[y][x]] for x in range(W)) for y in range(H)))

if __name__ == "__main__":
    main()
