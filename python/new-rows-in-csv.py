#!/usr/bin/env python

import csv
import sys

original_ids = set()

with open(sys.argv[1], newline='') as original_file:
    reader = csv.DictReader(original_file)
    for row in reader:
        original_ids.add(row['groupId'])

field_names = ['groupId', 'groupName', 'setId', 'reason']

with open(sys.argv[2], newline='') as new_file:
    reader = csv.DictReader(new_file)
    writer = csv.DictWriter(sys.stdout, fieldnames=field_names)
    for row in reader:
        if row['groupId'] in original_ids:
            continue

        writer.writerow(row)

