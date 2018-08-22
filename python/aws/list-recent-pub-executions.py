#!/usr/bin/env python

import boto3
import json
import sys

client = boto3.client('stepfunctions')

executions = client.list_executions(
    stateMachineArn=sys.argv[1],
    maxResults=200
)

for e in executions['executions']:
    details = client.describe_execution(
        executionArn=e['executionArn']
    )

    irqs = ", ".join([str(x) for x in json.loads(details['input'])['irqIds']])

    sys.stdout.write(str(e['startDate']))
    sys.stdout.write("\t")
    sys.stdout.write(str(e['name']))
    sys.stdout.write("\t")
    sys.stdout.write(irqs)
    sys.stdout.write("\n")

sys.stdout.flush()
