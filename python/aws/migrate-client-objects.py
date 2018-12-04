#!/usr/bin/env python3

import sys
import boto3

from botocore.errorfactory import ClientError


if len(sys.argv) != 2:
    raise ValueError('Please provide the bucket name as an argument to the script!')
bucket_name = sys.argv[1]

s3 = boto3.client('s3')
rds = boto3.client('rds')

db_instances = []
result = rds.describe_db_instances(MaxRecords=100)
db_instances.extend(result['DBInstances'])

while 'Marker' in result:
    result = rds.describe_db_instances(MaxRecords=100, Marker=result['Marker'])
    db_instances.extend(result['DBInstances'])

print("Found " + str(len(db_instances)) + " DB instances.")


print("Checking S3 keys...")
for obj in s3.list_objects(Bucket=bucket_name, MaxKeys=1000)['Contents']:
    key = obj['Key']
    if not key.startswith("Beanstalk ") and not key.startswith("beanstalk/") and not key.startswith("package") and not key.startswith("Lambda Java v1_0"):
        continue

    segments = key.split("/")
    assert len(segments) == 3

    db_resource_name = segments[2].split(".")[0]

    found = False
    for db in db_instances:
        if db_resource_name in db['DBInstanceIdentifier']:
            found = True
            new_prefix = ""
            engine = db['Engine']
            if engine == 'postgres':
                new_prefix = "rds-postgres"
            elif engine == 'mysql':
                new_prefix = "rds-mysql"
            elif engine == 'aurora-postgresql':
                tags = rds.list_tags_for_resource(ResourceName=db['DBInstanceArn'])['TagList']
                for t in tags:
                    if t['Key'] == 'blueprint-service-type' and t['Value'] == 'RDS Aurora v1_0':
                        new_prefix = 'rds-aurora'
                    elif t['Key'] == 'blueprint-service-type' and t['Value'] == 'RDS Aurora Postgres v1_0':
                        new_prefix = 'rds-aurora-postgres'

            else:
                raise ValueError("Unrecognized engine type! " + engine)


            new_key = new_prefix + "/" + db_resource_name + "/" + segments[1] + ".yml"
            try:
                s3.head_object(Bucket=bucket_name, Key=new_key)
                print("NEW KEY ALREADY EXISTS, DELETING OLD KEY. Old: " + key + "  New: " + new_key)
                s3.delete_object(Bucket=bucket_name, Key=key)
                break
            except ClientError:
                # Not found
                pass


            print("MOVING KEY: " + key + "   ===>   " + new_key)
            copy_result = s3.copy_object(
                CopySource={
                    'Bucket': bucket_name,
                    'Key': key
                },
                CopySourceIfMatch=obj['ETag'],
                Bucket=bucket_name,
                Key=new_key,
                MetadataDirective='COPY',
                TaggingDirective='COPY')

            if copy_result['CopyObjectResult']['ETag'] == obj['ETag']:
                print("DELETING OLD KEY: " + key)
                s3.delete_object(Bucket=bucket_name, Key=key)
            else:
                raise ValueError("COPY FAILED! " + str(copy_result))

            break

    if not found:
        print("Deleting orphaned key: " + key)
        s3.delete_object(Bucket=bucket_name, Key=key)
