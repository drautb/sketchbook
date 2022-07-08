#!/usr/bin/env python

import math
import sys

LIMIT = int(sys.argv[1])

size = math.ceil(math.log(LIMIT, 2))

print("state")
for x in range(LIMIT):
  print("{0:0{size}b}".format(x, size=size))
