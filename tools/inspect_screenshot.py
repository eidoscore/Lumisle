import sys, struct, zlib

# Minimal PNG reader (no PIL dependency) — decode to RGBA pixels, report dominant colors.
def read_png(path):
    with open(path, 'rb') as f:
        data = f.read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', "not png"
    pos = 8
    width = height = bitdepth = colortype = 0
    idat = b''
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        ctype = data[pos+4:pos+8]
        chunk = data[pos+8:pos+8+length]
        if ctype == b'IHDR':
            width, height, bitdepth, colortype = struct.unpack('>IIBB', chunk[:10])
        elif ctype == b'IDAT':
            idat += chunk
        elif ctype == b'IEND':
            break
        pos += 12 + length
    raw = zlib.decompress(idat)
    channels = {0:1, 2:3, 3:1, 4:2, 6:4}[colortype]
    stride = width * channels
    # Unfilter
    out = bytearray()
    prev = bytearray(stride)
    p = 0
    for y in range(height):
        ft = raw[p]; p += 1
        line = bytearray(raw[p:p+stride]); p += stride
        if ft == 1:
            for i in range(channels, stride): line[i] = (line[i] + line[i-channels]) & 255
        elif ft == 2:
            for i in range(stride): line[i] = (line[i] + prev[i]) & 255
        elif ft == 3:
            for i in range(stride):
                a = line[i-channels] if i>=channels else 0
                line[i] = (line[i] + ((a + prev[i])>>1)) & 255
        elif ft == 4:
            for i in range(stride):
                a = line[i-channels] if i>=channels else 0
                b = prev[i]; c = prev[i-channels] if i>=channels else 0
                pp = a+b-c; pa=abs(pp-a); pb=abs(pp-b); pc=abs(pp-c)
                pr = a if (pa<=pb and pa<=pc) else (b if pb<=pc else c)
                line[i] = (line[i]+pr)&255
        out += line
        prev = line
    return width, height, channels, out

def main(path):
    w,h,ch,px = read_png(path)
    # Sample colors, count distinct saturated hues
    from collections import Counter
    c = Counter()
    for i in range(0, len(px), ch*53):  # sparse sample
        r,g,b = px[i], px[i+1], px[i+2]
        mx,mn = max(r,g,b), min(r,g,b)
        sat = mx-mn
        if sat > 60 and mx > 90:  # saturated, non-dark
            c[(r//48, g//48, b//48)] += 1
    print(f"{path}: {w}x{h} ch{ch} | saturated_buckets={len(c)} | top={c.most_common(5)}")

if __name__ == '__main__':
    for p in sys.argv[1:]:
        main(p)
