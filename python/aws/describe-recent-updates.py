#!/usr/bin/env python

import base64
import boto3
import json
import multiprocessing
import sys
import threading
import time

from threading import Thread

client = boto3.client('stepfunctions')

executions = client.list_executions(
    stateMachineArn=sys.argv[1],
    maxResults=int(sys.argv[2])
)

execution_arns = []
for e in executions['executions']:
    execution_arns.append(e['executionArn'])

# For each execution, gather the interesting events into a list of tuples
# where the first key is the timestamp for later sorting/printing.
messages = []

def gather_execution_data():
    while len(execution_arns) != 0:
        sys.stdout.write(".")
        sys.stdout.flush()

        arn = execution_arns.pop()
        execution_history = client.get_execution_history(
            executionArn=arn,
            maxResults=500
        )

        events = execution_history['events']
        waiting_for_lock = 0
        update_started = 0

        irq = json.loads(events[0]['executionStartedEventDetails']['input'])['irqIds'][0]
        start = events[0]['timestamp']

        if irq == -1:
            continue # Skip current events

        for e in events:
            msg = "[" + str(e['timestamp']) + "][" + str(irq) + "]"
            if e['type'] == 'ExecutionStarted':
                msg += "[Execution Started] IRQ=" + str(irq)
                messages.append((e['timestamp'], msg))
            elif e['type'] == 'TaskStateExited':
                name = e['stateExitedEventDetails']['name']
                output = json.loads(e['stateExitedEventDetails']['output'])
                msg += "[" + name + "] "

                if name == 'Check Redundancy':
                    msg += "Redundant? " + str(output['redundancy_check_results']['is_redundant'])

                elif name == 'Initiate Update':
                    if output['post_http_status_code'] == 409:
                        msg += "Failed to acquire lock!"
                        if waiting_for_lock == 0:
                            waiting_for_lock = e['timestamp']
                    else:
                        command_id = json.loads(base64.b64decode(output['post_body']['taskId']))['commandId']
                        if waiting_for_lock == 0:
                            waiting_for_lock = e['timestamp']
                        waiting_for_lock = e['timestamp'] - waiting_for_lock
                        msg += "Command Id: " + command_id + " (Waited " + str(waiting_for_lock) + " for lock)"
                        update_started = e['timestamp']

                if name == 'Get Update Status':
                    update_duration = e['timestamp'] - update_started;
                    msg += " Update completed in " + str(update_duration)

                if name == 'Return Success' or name == 'Return Nothing To Do':
                    msg += "Total Duration: " + str(e['timestamp'] - start)

                messages.append((e['timestamp'], msg))

threads = []
for _ in range(multiprocessing.cpu_count()):
    t = Thread(target=gather_execution_data)
    t.start()
    threads.append(t)

for t in threads:
    t.join()

print ""
for time,msg in sorted(messages, key=lambda x: x[0]):
    print msg
