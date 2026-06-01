"""Verifikasi lanjutan: (1) ketiga screenshot BEDA satu sama lain (navigasi jalan),
(2) di game screen, sampel pusat tile menghasilkan beberapa warna berbeda (board
ter-render), (3) latar atas layar bukan abu default (#3b3b3b-ish)."""
import numpy as np
from PIL import Image

def load(p):
    return np.asarray(Image.open(p).convert("RGB"))

menu = load("export/qa_menu.png")
lm = load("export/qa_levelmap.png")
game = load("export/qa_game.png")

def diff(a, b):
    n = min(a.shape[0], b.shape[0])
    return float(np.abs(a[:n].astype(int) - b[:n].astype(int)).mean())

print("diff menu vs levelmap:", round(diff(menu, lm), 2))
print("diff levelmap vs game:", round(diff(lm, game), 2))
print("diff menu vs game:", round(diff(menu, game), 2))

# Warna latar di pojok atas (y=120) — harus warna langit gradien, bukan abu Godot.
for name, img in [("menu", menu), ("levelmap", lm), ("game", game)]:
    top = img[120, 540]
    print(f"{name} top-center pixel RGB = {tuple(int(v) for v in top)}")

# Sampel pusat tile board (game) — kumpulkan warna unik dominan.
ox, oy, ts = 155, 535, 110
seen = {}
for gy in range(8):
    for gx in range(7):
        cx, cy = ox + gx * ts + ts // 2, oy + gy * ts + ts // 2
        if cy < game.shape[0] and cx < game.shape[1]:
            r, g, b = (int(v) for v in game[cy, cx])
            key = (r // 40, g // 40, b // 40)
            seen[key] = seen.get(key, 0) + 1
print("distinct tile-center color buckets on board:", len(seen))
