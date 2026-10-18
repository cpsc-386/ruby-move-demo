# Writes a white, anti-aliased filled circle PNG with no outline. The game
# tints it to each circle's color, so every pixel (even transparent ones) is
# white to avoid a dark fringe.
#
# Usage: python3 scripts/make_circle.py [output.png]
#        (default: mygame/sprites/solid-circle.png)
import os, struct, zlib, sys

DEFAULT_OUTPUT = os.path.join(os.path.dirname(__file__), "..", "mygame", "sprites", "solid-circle.png")

N, SS = 256, 4                      # image size, supersamples per axis
r = N / 2
rows = []
for y in range(N):
    row = bytearray([0])            # PNG filter type: none
    for x in range(N):
        hits = 0
        for sy in range(SS):
            for sx in range(SS):
                dx = x + (sx + 0.5) / SS - r
                dy = y + (sy + 0.5) / SS - r
                hits += dx * dx + dy * dy <= r * r
        row += bytes([255, 255, 255, round(255 * hits / (SS * SS))])
    rows.append(bytes(row))
def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
       + chunk(b"IEND", b""))
open(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUTPUT, "wb").write(png)
