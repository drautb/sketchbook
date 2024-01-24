#!/usr/bin/env bash

command="$1"
attempts="$2"

echo "Executing \"$command\" $attempts times..."

successes=0
failures=0

for i in $(seq 1 $attempts); do 
  echo "Attempt $i/$attempts..."
  eval " $command"
  if $command; then
    successes=$((successes+1))
  fi
done

echo "*** COMPLETE ***"
echo "  $successes/$attempts Succeeded"


