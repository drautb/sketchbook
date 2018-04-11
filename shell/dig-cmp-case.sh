#!/usr/bin/env bash

# This script will sample a dig query many times, and count how many times a
# case difference was observed between the question and answer.

set -e

SAMPLE_COUNT=$1
HOST=$2
SERVER=${3:-""}

consistent_replies=0

for _ in $(seq 1 $SAMPLE_COUNT); do
  if [ "$SERVER" == "" ]; then
    response=$(dig "$HOST")
  else
    response=$(dig @"$SERVER" "$HOST")
  fi

  exact_matches=$(echo "$response" | grep -o "$HOST" | wc -l)
  i_matches=$(echo "$response" | grep -io "$HOST" | wc -l)

  if [ "$exact_matches" == "$i_matches" ]; then
    consistent_replies=$((consistent_replies+1))
  fi
done

percent=$(awk "BEGIN { pc=100*${consistent_replies}/${SAMPLE_COUNT}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
printf "%d/%d consistent replies. (%d%%) \\n" "$consistent_replies" "$SAMPLE_COUNT" "$percent"
