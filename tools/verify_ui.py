"""Definitive UI-vs-logic verification.

For each turn: read what is DISPLAYED (pixels) and what the engine board ACTUALLY is
(logcat LUMISLE_BOARD), print both side-by-side, count mismatches. Then execute an
oracle-chosen valid move and repeat. Zero mismatches => the rendered UI is faithful.
"""
import subprocess, time, re, sys
from collections import Counter
import uiautomator2 as u2

SERIAL = "ytjjkbi7bucyjzyl"
ADB = r"C:\Users\khoer\AppData\Local\Android\Sdk\platform-tools\adb.exe"
GODOT = r"d:\Project\eidosMobile\Godot_v4.6.3-stable_win64\godot_console.exe"
PROJ = r"d:\Project\eidosMobile\Lumisle"
OX, OY, TS, W, H = 115, 575, 110, 7, 8
NAMES = {0: ".", 1: "R", 2: "B", 3: "G", 4: "Y", 5: "P", 6: "O"}


def adb(*a):
    return subprocess.run([ADB, *a], capture_output=True, text=True, timeout=30).stdout


def classify(p):
    r, g, b = p[0], p[1], p[2]
    if r > 230 and g > 190 and b < 45: return -1   # hint yellow -> ignore
    if r > 235 and g > 235 and b > 235: return -1  # white hint border -> ignore
    if max(r, g, b) - min(r, g, b) < 35: return 0
    if r > 180 and g < 140 and b < 140: return 1
    if b > 150 and r < 150: return 2
    if g > 150 and r < 160 and b < 160: return 3
    if r > 210 and g > 160 and 45 <= b < 120: return 4
    if r > 140 and b > 170 and g < 150: return 5
    if r > 210 and g > 120 and b < 110: return 6
    return 0


def read_pixels(d):
    px = d.screenshot().load()
    grid = []
    for y in range(H):
        row = []
        for x in range(W):
            cx, cy = OX + x*TS, OY + y*TS
            votes = Counter()
            for ox, oy in ((0,0), (-30,-30), (30,-30), (-30,30), (30,30), (0,-32), (0,32)):
                c = classify(px[cx+ox, cy+oy])
                if c >= 0:
                    votes[c] += 1
            row.append(votes.most_common(1)[0][0] if votes else 0)
        grid.append(row)
    return grid


def read_logcat():
    out = adb("logcat", "-d", "-s", "godot:*")
    m = re.findall(r"LUMISLE_BOARD (\S+) ([RBGYPO\.\*/]+)", out)
    if not m:
        return None
    tag, gs = m[-1]
    rows = [r for r in gs.split("/") if r]
    grid = [[{"R":1,"B":2,"G":3,"Y":4,"P":5,"O":6,".":0,"*":7}.get(ch,0) for ch in r] for r in rows]
    return tag, grid


def oracle_moves(grid):
    gs = "/".join("".join(NAMES.get(c if c!=7 else 1, ".") for c in row) for row in grid)
    out = subprocess.run([GODOT, "--headless", "--path", PROJ, "-s", "tools/oracle_moves.gd",
                          "--", f"--grid={gs}"], capture_output=True, text=True, timeout=60).stdout
    mv = []
    for line in out.splitlines():
        if line.strip().startswith("MOVE "):
            ax, ay, bx, by = [int(v) for v in line.strip()[5:].replace(",", " ").split()]
            mv.append(((ax, ay), (bx, by)))
    return mv


def show(disp, logic):
    print("    DISPLAYED(pixels)        ENGINE(logcat)")
    for y in range(H):
        dl = " ".join(NAMES.get(disp[y][x], "?") for x in range(W))
        ll = " ".join((NAMES.get(logic[y][x], "?") if logic[y][x]!=7 else "*") for x in range(W))
        mark = "" if all(disp[y][x]==logic[y][x] or logic[y][x]==7 for x in range(W)) else "  <-- MISMATCH"
        print(f"r{y}  {dl}    {ll}{mark}")


def mismatches(disp, logic):
    return sum(1 for y in range(H) for x in range(W)
               if logic[y][x] != 7 and disp[y][x] != logic[y][x])


def main():
    d = u2.connect(SERIAL)
    d.app_stop("com.eidoscore.lumisle"); time.sleep(1)
    adb("logcat", "-c")
    d.app_start("com.eidoscore.lumisle"); time.sleep(6)
    d.click(540, 1070); time.sleep(3)
    d.click(540, 1130); time.sleep(3)
    turns = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    for t in range(turns):
        time.sleep(1.0)
        lg = read_logcat()
        disp = read_pixels(d)
        if not lg:
            print(f"TURN {t+1}: no logcat board"); continue
        tag, logic = lg
        print(f"\n===== TURN {t+1}  (engine dump tag={tag}) =====")
        show(disp, logic)
        mm = mismatches(disp, logic)
        print(f"MISMATCHES displayed-vs-engine: {mm}")
        mv = oracle_moves(logic)
        if not mv:
            print("no moves"); break
        a, b = mv[0]
        ax, ay = OX+a[0]*TS, OY+a[1]*TS
        bx, by = OX+b[0]*TS, OY+b[1]*TS
        print(f"executing {a} <-> {b}")
        d.swipe(ax, ay, bx, by, duration=0.18)
        time.sleep(2.2)


if __name__ == "__main__":
    main()
