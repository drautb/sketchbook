#!/usr/bin/env python3

# Generates a sequence of PNG files that can be used as a mask to make a dissovling transition.

import math
import numpy as np
import os
import random
import sys

from PIL import Image

# ./generate-pngs.py 800 600 10 60
WIDTH = int(sys.argv[1])
HEIGHT = int(sys.argv[2])
SQUARE_SIZE = int(sys.argv[3])
FRAME_COUNT = int(sys.argv[4])

assert WIDTH > 0
assert HEIGHT > 0
assert SQUARE_SIZE > 0
assert FRAME_COUNT > 1
assert WIDTH % SQUARE_SIZE == 0
assert HEIGHT % SQUARE_SIZE == 0

SQUARE_COUNT = int((WIDTH / SQUARE_SIZE) * (HEIGHT / SQUARE_SIZE))

assert SQUARE_COUNT % FRAME_COUNT == 0

SQUARES_PER_FRAME = int(SQUARE_COUNT / FRAME_COUNT)

square_indices = list(range(0, SQUARE_COUNT))
random.shuffle(square_indices)

data = np.zeros((HEIGHT, WIDTH), dtype=np.uint8)

os.makedirs("pngs", exist_ok=True)
for f in range(0, FRAME_COUNT):
    for _ in range(0, SQUARES_PER_FRAME):
        square = square_indices.pop()
        start_x = (square * SQUARE_SIZE) % WIDTH
        start_y = math.floor((square * SQUARE_SIZE) / WIDTH) * SQUARE_SIZE
        for y in range(start_y, start_y + SQUARE_SIZE):
            for x in range(start_x, start_x + SQUARE_SIZE):
                data[y,x] = 255

    img = Image.frombuffer('L', (WIDTH, HEIGHT), data)
    img.save(f"pngs/frame{f:03d}.png")
            
