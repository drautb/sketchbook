#!/usr/bin/env bash

set -e

FILE=$1
SAMPLES=$2
SERVER=${3:-""}

while read line; do
  echo "Checking $line..."
  ./dig-cmp-case.sh "$SAMPLES" "$line" "$SERVER"
done <"$FILE"
