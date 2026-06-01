"""QA visual (Fase 4.5 art) — navigasi device + analisa screenshot OBJEKTIF.

PENTING geometri: viewport 1080x1920, layar 1080x2400, stretch=keep →
letterbox atas/bawah 240px. device_y = game_y + 240, device_x = game_x (skala 1.0).

Mengukur: warna unik+entropi (latar polos default = rendah), variasi bentuk tile,
dan MEMASTIKAN tiap langkah navigasi benar-benar mengubah layar (diff > ambang).
"""
import subprocess, time, io
import numpy as np
from PIL import Image

ADB = r"C:\Users\khoer\AppData\Local\Android\Sdk\platform-tools\adb.exe"
SERIAL = "ytjjkbi7bucyjzyl"
PKG = "com.eidoscore.lumisle"
LETTERBOX = 240  # px atas


def adb(*args):
    return subprocess.run([ADB, "-s", SERIAL, *args], capture_output=True)


def screencap():
    out = adb("exec-out", "screencap", "-p").stdout
    return Image.open(io.BytesIO(out)).convert("RGB")


def tap_game(gx, gy):
    """Tap memakai koordinat game-space (otomatis +letterbox)."""
    adb("shell", "input", "tap", str(int(gx)), str(int(gy + LETTERBOX)))


def analyze(img, name):
    a = np.asarray(img)
    h, w, _ = a.shape
    q = (a >> 3).astype(np.uint32)
    codes = (q[..., 0] << 10) | (q[..., 1] << 5) | q[..., 2]
    uniq, counts = np.unique(codes, return_counts=True)
    p = counts / counts.sum()
    entropy = float(-(p * np.log2(p)).sum())
    top = counts.max() / counts.sum()
    print(f"[{name}] {w}x{h} unique={len(uniq)} entropy={entropy:.2f} dominant={top*100:.1f}%")
    return entropy, top


def imdiff(a, b):
    a = np.asarray(a).astype(int); b = np.asarray(b).astype(int)
    n = min(a.shape[0], b.shape[0])
    return float(np.abs(a[:n] - b[:n]).mean())


def board_colors(img):
    a = np.asarray(img)
    ox, oy, ts = 155, 595, 110  # pusat tile (0,0) device: x=210,y=595? origin kiri-atas=155,540
    seen = {}
    for gy in range(8):
        for gx in range(7):
            cx = 210 + gx * ts
            cy = 595 + gy * ts
            if cy < a.shape[0] and cx < a.shape[1]:
                r, g, b = (int(v) for v in a[cy, cx])
                seen[(r // 40, g // 40, b // 40)] = 1
    return len(seen)


def main():
    adb("shell", "am", "force-stop", PKG)
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(6)

    menu = screencap(); menu.save("export/qa_menu.png")
    analyze(menu, "menu")

    # Tombol "Main" (VBox center 540,960 + offset_top 200 → btn1 game y≈1220).
    tap_game(540, 1220); time.sleep(2)
    lm = screencap(); lm.save("export/qa_levelmap.png")
    analyze(lm, "levelmap")
    d1 = imdiff(menu, lm)
    print(f"  nav menu->levelmap diff={d1:.2f} {'OK pindah' if d1 > 5 else 'TIDAK PINDAH!'}")

    # Level pertama: Scroll game top=360, btn1 center game y≈360+48=408.
    tap_game(540, 410); time.sleep(3)
    game = screencap(); game.save("export/qa_game.png")
    analyze(game, "game")
    d2 = imdiff(lm, game)
    nb = board_colors(game)
    print(f"  nav levelmap->game diff={d2:.2f} {'OK pindah' if d2 > 5 else 'TIDAK PINDAH!'}")
    print(f"  board distinct tile colors = {nb} {'OK' if nb >= 4 else 'KURANG'}")

    # Kembali ke meta? (lewati) — cek meta dari menu langsung di run lain.
    print("\nRESULT:",
          "PASS" if (d1 > 5 and d2 > 5 and nb >= 4) else "REVIEW")


if __name__ == "__main__":
    main()
