#!/usr/bin/env python

import base64
import boto3
import json
import multiprocessing
import sys

from threading import Thread
from botocore.config import Config

if len(sys.argv) != 3:
    print "Usage: describe-config-update.py <state machine arn> <irq id>"
    exit(1)

config = Config(
    retries = dict(
        max_attempts = 10
    )
)
client = boto3.client('stepfunctions', config=config)

execution_arns = []
target_arns = []

def check_irq():
    while len(execution_arns) != 0 and len(target_arns) == 0:
        sys.stdout.write(".")
        sys.stdout.flush()

        arn = execution_arns.pop()
        history = client.get_execution_history(executionArn=arn)
        irq = json.loads(history['events'][0]['executionStartedEventDetails']['input'])['irqIds'][0]

        if irq == int(sys.argv[2]):
            target_arns.append(arn)

next_token = None
while len(target_arns) == 0:
    if next_token != None:
        executions = client.list_executions(stateMachineArn=sys.argv[1], maxResults=50, nextToken=next_token)
    else:
        executions = client.list_executions(stateMachineArn=sys.argv[1], maxResults=50)

    for e in executions['executions']:
        execution_arns.append(e['executionArn'])

    threads = []
    for _ in range(multiprocessing.cpu_count()):
        t = Thread(target=check_irq)
        t.start()
        threads.append(t)

    for t in threads:
        t.join()

    if len(target_arns) == 0:
        next_token == executions['nextToken']

print "\nFound target ARN(s) for IRQ " + sys.argv[2] + ": " + str(target_arns)
exit(0)

execution_history = client.get_execution_history(
    executionArn=sys.argv[1],
    maxResults=500
)

events = execution_history['events']
waiting_for_lock = 0

irq = str(json.loads(events[0]['executionStartedEventDetails']['input'])['irqIds'][0])
start = events[0]['timestamp']

for e in events:
    msg = "[" + str(e['timestamp']) + "][" + irq + "]"
    if e['type'] == 'ExecutionStarted':
        msg += "[Execution Started] IRQ=" + irq
        print msg
    elif e['type'] == 'TaskStateExited':
        name = e['stateExitedEventDetails']['name']
        output = json.loads(e['stateExitedEventDetails']['output'])
        msg += "[" + name + "] "

        if name == 'Check Redundancy':
            msg += "Redundant? " + str(output['redundancy_check_results']['is_redundant'])

        if name == 'Initiate Update':
            if output['post_http_status_code'] == 409:
                msg += "Failed to acquire lock!"
                if waiting_for_lock == 0:
                    waiting_for_lock = e['timestamp']
            else:
                command_id = json.loads(base64.b64decode(output['post_body']['taskId']))['commandId']
                waiting_for_lock = e['timestamp'] - waiting_for_lock
                msg += "Command Id: " + command_id + " (Waited " + str(waiting_for_lock) + " for lock)"
                update_started = e['timestamp']

        if name == 'Get Update Status':
            update_duration = e['timestamp'] - update_started
            msg += "Update completed in " + str(update_duration)

        if name == 'Return Success' or name == 'Return Nothing To Do':
            msg += "Total Duration: " + str(e['timestamp'] - start)

        print msg
