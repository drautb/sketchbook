#!/usr/bin/env python

import base64
import boto3
import json
import sys

client = boto3.client('stepfunctions')

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
