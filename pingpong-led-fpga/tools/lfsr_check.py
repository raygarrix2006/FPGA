#!/usr/bin/env python3
"""Check the 8-bit LFSR used in src/pingpong.vhd.

Same update rule as the VHDL:
    lfsr <= lfsr(6 downto 0) & (lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3))
Seed x"A5". A maximal-length 8-bit LFSR has period 255.
"""
SEED = 0xA5

q = SEED
seen = set()
period = 0
while q not in seen:
    seen.add(q)
    fb = ((q >> 7) ^ (q >> 5) ^ (q >> 4) ^ (q >> 3)) & 1
    q = ((q << 1) & 0xFF) | fb
    period += 1

print(f"period = {period}")
print(f"returns to seed = {q == SEED}")
print(f"distinct states visited = {len(seen)}")
assert period == 255 and q == SEED, "LFSR is not maximal-length"
print("OK")
