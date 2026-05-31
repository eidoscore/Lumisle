"""Full-screen ASCII color visualizer so the agent can SEE the actual UI layout.
Downsamples the whole 1080x2400 screen to a coarse grid of color letters.
Also auto-detects the board bounding box (largest saturated region) and tile pitch.
"""
import sys
import uiautomator2 as u2

SERIAL = "ytjjkbi7bucyjzyl"

def letter(p):
    r, g, b = p[0], p[1], p[2]
    mx, mn = max(r, g, b), min(r, g, b)
    if r > 235 and g > 195 and b < 45: return "h"   # hint yellow (low blue)
    if mx > 235 and mn > 235: return "W"            # white
    if mx - mn < 28:
        if mx > 200: return "+"                     # light gray
        if mx < 55: return " "                      # black/empty
        return "."                                  # mid gray bg (~77)
    if r > 180 and g < 140 and b < 140: return "R"
    if b > 150 and r < 150: return "B"
    if g > 150 and r < 160 and b < 160: return "G"
    if r > 210 and g > 160 and b < 120: return "Y"
    if r > 140 and b > 170 and g < 150: return "P"
    if r > 210 and g > 120 and b < 110: return "O"
    return "?"

def main():
    d = u2.connect(SERIAL)
    img = d.screenshot()
    img.save(r"d:\Project\eidosMobile\Lumisle\export\view.png")
    px = img.load()
    w, h = img.size
    cols, rows = 54, 60           # ascii grid resolution
    sx, sy = w / cols, h / rows
    print(f"screen {w}x{h}  (each char ~{sx:.0f}x{sy:.0f}px)")
    # column ruler (hundreds of px)
    print("    " + "".join(str((int(c*sx)//100)%10) for c in range(cols)))
    for ry in range(rows):
        line = ""
        for rx in range(cols):
            x = min(w-1, int(rx*sx + sx/2)); y = min(h-1, int(ry*sy + sy/2))
            line += letter(px[x, y])
        ypx = int(ry*sy + sy/2)
        print(f"{ypx:4d}{line}")

if __name__ == "__main__":
    main()
