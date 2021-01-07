#!/usr/bin/env python3

import sys
import boto3

from botocore.errorfactory import ClientError

if len(sys.argv) != 3:
    raise ValueError('Please provide the file name and bucket name as arguments to the script!')

filename = sys.argv[1]
bucket_name = sys.argv[2]

with open(filename) as f:
    lines = [line.rstrip() for line in f]

s3 = boto3.client('s3')

low = 0
high = len(lines)
mid = int(high / 2)

while low < high and (high - low) > 1:
  print("Checking idx " + str(mid) + " (LOW: " + str(low) + ", HIGH: " + str(high) + "   -   " + str(lines[mid]) + ")");

  try:
    s3.get_object_acl(Bucket=bucket_name, Key=lines[mid])
    low = mid
    mid = int((high - mid) / 2) + low
  except:
    high = mid
    mid = int((mid - low) / 2) + low


print("Result: " + str(mid))
print(lines[mid])



