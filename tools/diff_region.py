import sys
from inspect_screenshot import read_png

# Compare two screenshots within a device-pixel rectangle; report % of changed pixels.
# Usage: python diff_region.py before.png after.png x0 y0 x1 y1
def main(a, b, x0, y0, x1, y1):
    wa, ha, ca, pa = read_png(a)
    wb, hb, cb, pb = read_png(b)
    if (wa, ha) != (wb, hb):
        print(f"size mismatch {wa}x{ha} vs {wb}x{hb}")
        return
    changed = 0
    total = 0
    for y in range(y0, y1, 4):
        for x in range(x0, x1, 4):
            ia = (y * wa + x) * ca
            ib = (y * wb + x) * cb
            da = abs(pa[ia] - pb[ib]) + abs(pa[ia+1] - pb[ib+1]) + abs(pa[ia+2] - pb[ib+2])
            total += 1
            if da > 40:
                changed += 1
    pct = (changed * 100.0 / total) if total else 0
    print(f"region ({x0},{y0})-({x1},{y1}): {changed}/{total} px changed = {pct:.1f}%")

if __name__ == '__main__':
    a, b = sys.argv[1], sys.argv[2]
    x0, y0, x1, y1 = map(int, sys.argv[3:7])
    main(a, b, x0, y0, x1, y1)
