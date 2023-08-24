#!/usr/bin/env python3

# Forcefully delete a bucket, including all objects, object versions, etc.

import sys
import boto3

from botocore.errorfactory import ClientError


if len(sys.argv) < 4:
  raise ValueError('Usage: nuke-bucket.py <PROFILE> <REGION> <BUCKET NAME> ... <BUCKET NAME>')

profile = sys.argv[1]
region = sys.argv[2]
buckets = sys.argv[3:]

session = boto3.Session(profile_name=profile, region_name=region)

s3 = session.resource('s3')

for b in buckets:
  print("Nuking bucket: " + b)
  bucket = s3.Bucket(b)

  print("  Deleting objects...")
  bucket.object_versions.delete()

  print("  Deleting bucket...")
  bucket.delete()



