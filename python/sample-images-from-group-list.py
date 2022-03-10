#!/usr/bin/env python

import random
import sys
import pandas as pd

FILE=sys.argv[1]
COUNT=int(sys.argv[2])
SEED=int(sys.argv[3])

if SEED:
    random.seed(SEED)

df = pd.read_csv(FILE)

groups = df.sample(COUNT, replace=True, weights=df['Image_Count'], random_state=SEED if SEED else random.getstate())
for _, row in groups.iterrows():
    image = random.randint(1, row["Image_Count"])
    print(f'{row["Group"]:09d}_{image:05d}')

