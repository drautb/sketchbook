#!/usr/bin/env python3

import sys

INPUT_FILE = sys.argv[1]

f = open(INPUT_FILE, 'r')
lines = f.readlines()
f.close()

keep_lines = []
trimmed_lines = set()

for i in range(len(lines)):    
    l = lines[i]
    segments = l.split('\t')
    enamex = segments[1]

    if l in trimmed_lines:
        continue

    keep_lines.append(l)
    for i2 in range(i + 1, len(lines)):
        l2 = lines[i2]
        if enamex in l2 and (not l2 in trimmed_lines):
            trimmed_lines.add(l2)

for l in keep_lines:
    print(l, end='', flush=True)

sys.stderr.write(f"Trimmed {len(trimmed_lines)} cases.\n")

f = open("trimmed-by-script", 'w')
for l in trimmed_lines:
    f.write(l)
f.close()

