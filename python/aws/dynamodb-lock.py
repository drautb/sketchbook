#!/usr/bin/env python

# Simple script for testing a locking strategy with dynamodb.

import boto3
import random
import sys
import threading
import time

from botocore.exceptions import ClientError

table_name = 'locks'


def get_dynamodb_client():
    return boto3.client('dynamodb',
                        endpoint_url='http://localhost:8000',
                        region_name='us-east-1',
                        aws_access_key_id="anything",
                        aws_secret_access_key="anything")


def ensure_table_exists():
    # Create the DynamoDB table.
    dynamodb = get_dynamodb_client()
    existing_tables = dynamodb.list_tables()['TableNames']

    if table_name in existing_tables:
        dynamodb.delete_table(TableName=table_name)

    dynamodb.create_table(
        TableName=table_name,
        KeySchema=[
            {
                'AttributeName': 'lock_name',
                'KeyType': 'HASH'
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'lock_name',
                'AttributeType': 'S'
            }
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 5,
            'WriteCapacityUnits': 5
        })


def acquire_lock(ddb, thread_name):
    response = None
    while response is None:
        try:
            response = ddb.put_item(
                TableName=table_name,
                Item={
                    'lock_name': {
                        'S': 'this-is-the-lock'
                    },
                    'owner': {
                        'S': thread_name
                    },
                    'acquired': {
                        'N': str(int(time.time()))
                    }
                },
                # One of 3 conditions must be true to acquire the lock:
                # 1. The 'owner' attribute hasn't been created yet. (No one has acquired the lock before)
                # 2. The 'owner' attribute is 'None.' (The lock is available)
                # 3. The 'acquired' attribute is older than 3 seconds. (Whoever had the lock died.)
                ConditionExpression='#O = :none OR attribute_not_exists(#O) OR acquired < :three_seconds_ago',
                ExpressionAttributeNames={
                    '#O': 'owner'
                },
                ExpressionAttributeValues={
                    ':none': {
                        'S': 'None'
                    },
                    ':three_seconds_ago': {
                        'N': str(int(time.time()) - 3)
                    }
                })
        except ClientError as e:
            if e.response['Error']['Code'] != 'ConditionalCheckFailedException':
                raise
            time.sleep(0)  # Yield the CPU and then try again.


def release_lock(ddb, thread_name):
    ddb.put_item(
        TableName=table_name,
        Item={
            'lock_name': {
                'S': 'this-is-the-lock'
            },
            'owner': {
                'S': 'None'
            },
            'acquired': {
                'N': '0'
            }
        },
        ConditionExpression='#O = :self',
        ExpressionAttributeNames={
            '#O': 'owner'
        },
        ExpressionAttributeValues={
            ':self': {
                'S': thread_name
            }
        })


# The counter starts at zero. If the lock is correct, we would expect counter to
# be exaclty (thread_count * increments_per_thread) once all threads have completed.
# If the lock is _not_ correct, then we'll have either more or less.
thread_count = int(sys.argv[1])
increments_per_thread = int(sys.argv[2])
counter = 0


class StressTest(threading.Thread):
    def run(self):
        global counter
        global increments_per_thread
        ddb = get_dynamodb_client()

        for n in range(increments_per_thread):
            acquire_lock(ddb, self.getName())

            # BEGIN CRITICAL SECTION
            counter += 1
            if counter % 1000 == 0:
                print "Counter Progress: %d" % counter

            if random.randint(1, 1000) == 42:
                print "[%s] Simulating failure, not releasing lock." % self.getName()
            else:
                # END CRITICAL SECTION
                release_lock(ddb, self.getName())

# Run a bunch of threads to stress test the lock.
if __name__ == '__main__':
    print "Creating DynamoDB Table..."
    ensure_table_exists()

    start = time.time()

    print "Thread Count: %d\nIncrements Per Thread: %d" % (thread_count, increments_per_thread)
    threads = []
    for n in range(thread_count):
        t = StressTest(name="Thread{}".format(n + 1))
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    end = time.time()

    print "\nAll threads done!\nTime Elapsed: %d seconds.\n" % (end - start)
    print "Counter:  %d\nExpected: %d\n" % (counter, thread_count * increments_per_thread)
