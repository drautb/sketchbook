#!/usr/bin/env python

import boto3
import functools
import json
import operator
import sys

from pprint import pprint

INLINE_LENGTH_LIMIT = 10240.0

role_name = sys.argv[1]

iam = boto3.client('iam')

result = iam.list_role_policies(RoleName=role_name)
policy_names = result['PolicyNames']

policies = {}
for p in policy_names:
    response = iam.get_role_policy(RoleName=role_name, PolicyName=p)
    policies[response['PolicyName']] = response['PolicyDocument']

total_length = 0
for n, d in policies.items():
    condensed_str = json.dumps(d, separators=(',', ':'))
    length = len(condensed_str)
    print(n + ': ' + str(length))
    total_length += length

pct = int((total_length / INLINE_LENGTH_LIMIT) * 100)
print('\nTotal Length: ' + str(total_length) + '/' + str(int(INLINE_LENGTH_LIMIT)) + ' (' + str(pct) + '%)\n')


#######################################################################
# Begin Reduction
#

def get_stmt_keys(stmt):
    all_keys = stmt.keys()
    if 'Sid' in all_keys:
        all_keys.remove('Sid')
    all_keys.sort()
    return all_keys

# Collect all statements
stmts = []
for n, d in policies.items():
    stmts.extend(d['Statement'])

print('Attempting to collapse ' + str(len(stmts)) + ' statements...')


# Group statements by key sets. (Same keys in statement, except for sid)
matching_key_groups = []

for s in stmts:
    all_keys = get_stmt_keys(s)

    matched = False
    for g in matching_key_groups:
        if get_stmt_keys(g[0]) == all_keys:
            g.append(s)
            matched = True
            break

    if not matched:
        matching_key_groups.append([s])

print('Found ' + str(len(matching_key_groups)) + ' groups of unique key sets...')

#######################################################################
# Further subdivide each group of statements by other keys in the statement

foldl = lambda func, acc, xs: functools.reduce(func, xs, acc)

def group_by(stmts, key):
    # Return early if this group doesnt have the given key
    if len(stmts) > 0 and key not in stmts[0].keys():
        return [stmts]

    groups = []
    for s in stmts:
        matched = False
        for g in groups:
            if g[0][key] == s[key]:
                g.append(s)
                matched = True
                break

        if not matched:
            groups.append([s])

    return groups


STMT_KEYS = ['Effect', 'Principal', 'NotPrincipal', 'Action', 'NotAction', 'Condition']

groups = matching_key_groups
for k in STMT_KEYS:
    groups = foldl(operator.add, [], map(lambda g: group_by(g, k), groups))

print('Found ' + str(len(groups)) + ' candidate groups for collapse...')

collapsed_statements = []
for g in groups:
    if len(g) == 1:
        collapsed_statements.extend(g)
        continue

    all_resources = map(lambda s: s['Resource'] if 'Resource' in s else [], g)
    all_not_resources = map(lambda s: s['NotResource'] if 'NotResource' in s else [], g)

    s = g[0]
    if len(all_resources) != 0:
        s['Resource'] = list(set(foldl(operator.add, [], all_resources)))
    else:
        s['NotResource'] = list(set(foldl(operator.add, [], all_not_resources)))

    collapsed_statements.append(s)

collapsed_policy = {
    'Version': '2012-10-17',
    'Statement': collapsed_statements
}

print('\nCollapsed ' + str(len(stmts)) + ' statements into ' + str(len(collapsed_statements)))

new_condensed_str = json.dumps(collapsed_policy, separators=(',', ':'))
new_length = len(new_condensed_str)

pct = int((new_length / INLINE_LENGTH_LIMIT) * 100)
print('Collapsed Total Length: ' + str(new_length) + '/' + str(int(INLINE_LENGTH_LIMIT)) + ' (' + str(pct) + '%)\n')

reduction_pct = (total_length - new_length) / (1.0 * total_length) * 100.0
print('Inline policy size reduced by ' + str(int(reduction_pct)) + '%')

print('\nNew Policy:')
print(json.dumps(collapsed_policy, indent=2, separators=(',', ': ')))
