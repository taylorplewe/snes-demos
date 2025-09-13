# HDMA Line-Counter bytes, which are written to NLTRx, consist of the following format:
#   7  bit  0
#   ---- ----
#   RLLL LLLL
#   |||| ||||
#   |+++-++++- Number of scanlines left
#   +--------- Repeat flag

import struct

table = bytearray()

# generate Line-Counter byte
table.append(40)

# L > R = no window effect
table.append(2)
table.append(1)

# next Line-Counter byte at scanline 20
table.append(0x80 | 100)

for i in range(100):
    table.append(i + 34)
    table.append(i + 50)

table.append(224 - 140)
table.append(2)
table.append(1)

with open("bin/wh_lookup.bin", "wb") as f:
    for b in table:
        f.write(struct.pack("B", b))
