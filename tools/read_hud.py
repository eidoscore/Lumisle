"""Read the HUD area (moves + objective labels) via OCR-free brightness bands,
and dump the top region so we can see if counters update. Saves crops too."""
import uiautomator2 as u2
d = u2.connect("ytjjkbi7bucyjzyl")
img = d.screenshot()
img.save(r"d:\Project\eidosMobile\Lumisle\export\hud.png")
px = img.load(); w,h = img.size
# HUD labels: MovesLabel ~ game y120-170 -> device +240 = 360-410; Objective y175-225 -> 415-465.
# Instruction ~ game y1640 -> device 1880-1960.
def band(y0, y1, label):
    bright = 0; total = 0
    for y in range(y0, y1, 3):
        for x in range(60, 1000, 6):
            p = px[x,y]
            if p[0]>180 and p[1]>180 and p[2]>180:
                bright += 1
            total += 1
    print(f"{label} (y{y0}-{y1}): bright_text_px={bright}")
band(355, 415, "MOVES")
band(415, 470, "OBJECTIVE")
band(1880, 1975, "INSTRUCTION")
print("saved hud.png")
