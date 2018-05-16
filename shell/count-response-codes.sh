#!/usr/bin/env bash

set -e

SAMPLE_COUNT=$1
HOST=$2
CODE=$3

code_count=0

for _ in $(seq 1 $SAMPLE_COUNT); do
  response=$(curl -IsS "$HOST" | head -1 | cut -f 2 -d ' ')

  if [ "$response" == "$CODE" ]; then
    code_count=$((code_count+1))
  fi
done

percent=$(awk "BEGIN { pc=100*${code_count}/${SAMPLE_COUNT}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
printf "%d/%d $CODE responses. (%d%%) \\n" "$code_count" "$SAMPLE_COUNT" "$percent"
