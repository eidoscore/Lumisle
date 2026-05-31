"""Autonomous self-test using GROUND-TRUTH board from logcat (LUMISLE_BOARD).

Flow: install/launch -> navigate -> read true board from logcat -> oracle picks a
valid move (real Godot engine) -> swipe via u2 -> read true board again -> verify
the swap changed the board and left NO holes. Repeats for several turns.
No pixel vision needed for correctness; the game prints its own board state.
"""
import subprocess, time, re, sys
import uiautomator2 as u2

SERIAL = "ytjjkbi7bucyjzyl"
ADB = r"C:\Users\khoer\AppData\Local\Android\Sdk\platform-tools\adb.exe"
GODOT = r"d:\Project\eidosMobile\Godot_v4.6.3-stable_win64\godot_console.exe"
PROJ = r"d:\Project\eidosMobile\Lumisle"
OX, OY, TS, W, H = 115, 575, 110, 7, 8


def adb(*args):
    return subprocess.run([ADB, *args], capture_output=True, text=True, timeout=30).stdout


def last_board():
    out = adb("logcat", "-d", "-s", "godot:*")
    boards = re.findall(r"LUMISLE_BOARD (\S+) ([RBGYPO\.\*/]+)", out)
    return boards[-1] if boards else None


def holes(gridstr):
    return gridstr.count(".")


def oracle_moves(gridstr):
    # gridstr ends with trailing '/'; pass rows joined by '/'.
    rows = [r for r in gridstr.split("/") if r]
    grid = "/".join(rows)
    out = subprocess.run(
        [GODOT, "--headless", "--path", PROJ, "-s", "tools/oracle_moves.gd",
         "--", f"--grid={grid}"], capture_output=True, text=True, timeout=60).stdout
    mv = []
    for line in out.splitlines():
        if line.strip().startswith("MOVE "):
            ax, ay, bx, by = [int(v) for v in line.strip()[5:].replace(",", " ").split()]
            mv.append(((ax, ay), (bx, by)))
    return mv


def main():
    d = u2.connect(SERIAL)
    d.app_stop("com.eidoscore.lumisle"); time.sleep(1)
    adb("logcat", "-c")
    d.app_start("com.eidoscore.lumisle"); time.sleep(6)
    d.click(540, 1070); time.sleep(3)     # Play
    d.click(540, 1130); time.sleep(3)     # Level 1
    turns = int(sys.argv[1]) if len(sys.argv) > 1 else 4
    for t in range(turns):
        time.sleep(0.5)
        b = last_board()
        if not b:
            print(f"TURN {t+1}: no board log yet"); time.sleep(1); continue
        tag, grid = b
        print(f"\n== TURN {t+1} == last_dump={tag} holes={holes(grid)}")
        print("  " + grid.replace("/", "\n  "))
        mv = oracle_moves(grid)
        print(f"oracle moves={len(mv)}")
        if not mv:
            print("no valid move"); break
        a, bb = mv[0]
        ax, ay = OX + a[0]*TS, OY + a[1]*TS
        bx, by = OX + bb[0]*TS, OY + bb[1]*TS
        print(f"swipe {a} -> {bb}")
        d.swipe(ax, ay, bx, by, duration=0.18)
        time.sleep(2.0)
        b2 = last_board()
        if b2:
            print(f"  after: dump={b2[0]} holes={holes(b2[1])}")
            if b2[0] == tag:
                print("  !!! board dump tag unchanged — swap was REJECTED (no move consumed)")
            if holes(b2[1]) > 0:
                print("  !!! HOLES after settle")


if __name__ == "__main__":
    main()
