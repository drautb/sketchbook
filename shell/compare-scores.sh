#!/usr/bin/env bash

# Given a file containing two splunk events, this will produce a more
# readable diff between them.

events_file=$1

tmp_old=$(mktemp)
tmp_new=$(mktemp)

< "$events_file" jq -r -s -S '.[1].result._raw' | jq -S > "$tmp_old"
< "$events_file" jq -r -s -S '.[0].result._raw' | jq -S > "$tmp_new"

colordiff -y "$tmp_old" "$tmp_new"
