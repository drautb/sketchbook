#!/usr/bin/env python

import json
import sys
import boto3

DOMAIN = sys.argv[1]
WORKFLOW_ID = sys.argv[2]
RUN_ID = sys.argv[3]

DECISION_TASK_STARTED = 'DecisionTaskStarted'
ACTIVITY_TASK_STARTED = 'ActivityTaskStarted'

# IPs for prod-prod SysPS during original outage.
prod_prod_envs = {
  '10.36.86.228': '604-99a78c144730a686e87dd0ac8376 (5/20)',
  '10.36.71.211': '604-99a78c144730a686e87dd0ac8376 (5/20)',
  '10.36.64.185': '604-62c6761c4a038bc806a81555d848 (5/29)',
  '10.36.87.147': '604-62c6761c4a038bc806a81555d848 (5/29)',
  '10.36.91.114': '605-87dc435a40cdbe38688f9652efaa',
  '10.36.78.254': '605-87dc435a40cdbe38688f9652efaa'
}


IP_MAP = prod_prod_envs
swf_client = boto3.client('swf')


def get_workflow_history(swf_domain, workflow_id, run_id):
  return swf_client.get_workflow_execution_history(
    domain=swf_domain,
    execution = {
      'workflowId': workflow_id,
      'runId': run_id
    },
    maximumPageSize=1000)


def extract_ip(identity):
  # Identity looks like '3307@ip-10-36-91-114'
  return identity[identity.find('@ip-') + 4:].replace('-', '.')


def extract_identity(event):
  event_type = event['eventType']
  if event_type == DECISION_TASK_STARTED:
    return event['decisionTaskStartedEventAttributes']['identity']
  elif event_type == ACTIVITY_TASK_STARTED:
    return event['activityTaskStartedEventAttributes']['identity']


def get_id_label(event):
  return IP_MAP[extract_ip(extract_identity(event))]


def get_event_label(event_map, event):
  event_type = event['eventType']
  if event_type == DECISION_TASK_STARTED:
    return 'Decision Task'
  elif event_type == ACTIVITY_TASK_STARTED:
    scheduled_event_id = event['activityTaskStartedEventAttributes']['scheduledEventId']
    scheduled_event = event_map[scheduled_event_id]
    return scheduled_event['activityTaskScheduledEventAttributes']['activityType']['name']


def collect_started_events(event_list):
  started_events = []
  for e in event_list:
    event_type = e['eventType']
    if event_type == DECISION_TASK_STARTED or event_type == ACTIVITY_TASK_STARTED:
      started_events.append(e)

  return started_events


def collect_unique_identities(started_events):
  identities = set()
  for e in started_events:
    identities.add(get_id_label(e))
  ids = list(identities)
  ids.sort()
  return ids


def build_event_map(events):
  event_map = {}
  for e in events:
    event_map[e['eventId']] = e

  return event_map


def compute_max_column_width(event_map, started_events, identities):
  width = max(map(len, identities))
  for e in started_events:
    label_len = len(get_event_label(event_map, e))
    if label_len > width:
      width = label_len

  return width


def build_format_str(identities, col_width):
  format_str = '| {:>3} |'
  for i in identities:
    format_str += ' {:^' + str(col_width) + '} |'

  return format_str


print "Retrieving workflow history for workflow_id=" + WORKFLOW_ID
history = get_workflow_history(DOMAIN, WORKFLOW_ID, RUN_ID)

print "Computing execution graph..."
started_events = collect_started_events(history['events'])
identities = collect_unique_identities(started_events)
event_map = build_event_map(history['events'])
col_width = compute_max_column_width(event_map, started_events, identities)

format_str = build_format_str(identities, col_width)
print format_str.format('ID', *identities)
print '|-----|' + (('-' * (col_width + 2) + '|') * len(identities))

for e in started_events:
  label = get_event_label(event_map, e)
  cols = [''] * len(identities)

  cols[identities.index(get_id_label(e))] = label
  format_args = [e['eventId']] + cols

  print format_str.format(*format_args)

