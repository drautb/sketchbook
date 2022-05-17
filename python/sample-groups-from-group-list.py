#!/usr/bin/env python

import random
import sys
import pandas as pd

FILE=sys.argv[1]
GROUP_COLUMN=sys.argv[2]
IMAGE_COUNT_COLUMN=sys.argv[3]
COUNT=int(sys.argv[4])
SEED=int(sys.argv[5])

if SEED:
    random.seed(SEED)

df = pd.read_csv(FILE)

groups = df.sample(COUNT, replace=True, weights=df[IMAGE_COUNT_COLUMN], random_state=SEED if SEED else random.getstate())
for _, row in groups.iterrows():
    print(f'{row[GROUP_COLUMN]:09d},{row[IMAGE_COUNT_COLUMN]}')

