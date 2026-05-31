import sys
from inspect_screenshot import read_png

# Scan rows; report y-ranges where there's a bright horizontal band (button).
def main(path):
    w,h,ch,px = read_png(path)
    print(f"{path}: {w}x{h}")
    cx = w//2
    for y in range(0, h, 20):
        i = (y*w + cx)*ch
        r,g,b = px[i], px[i+1], px[i+2]
        bright = (r+g+b)//3
        bar = '#' * (bright//12)
        if bright > 40:
            print(f"y={y:4d} center_rgb=({r:3d},{g:3d},{b:3d}) {bar}")

if __name__ == '__main__':
    main(sys.argv[1])
