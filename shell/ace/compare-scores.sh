#!/usr/bin/env bash

# Given a file containing two splunk events, this will produce a more
# readable diff between them.

events_file="$1"
clean_file=$(mktemp)

# Schmutzes (⌨, \\u2328) break the colored output in my terminal for some reason.
sed 's/\\\\u2328//g' "$events_file" > "$clean_file"

tmp_old=$(mktemp)
tmp_new=$(mktemp)

< "$clean_file" jq -r -s -S '.[1].result._raw' | jq -S > "$tmp_old"
< "$clean_file" jq -r -s -S '.[0].result._raw' | jq -S > "$tmp_new"

colordiff -yW"$(tput cols)" "$tmp_old" "$tmp_new"
