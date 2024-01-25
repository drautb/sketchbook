#!/usr/bin/env bash

command="$1"
attempts="$2"

echo "Executing \"$command\" $attempts times..."

declare -A outcomes
output="$(mktemp)"

for _ in $(seq 1 "$attempts"); do
  eval " $command" >> "$output" 2>&1
  status="$?"

  if [ "$status" -eq 0 ]; then
    printf "."
  else
    printf "!"
  fi

  last_count="${outcomes["$status"]:-0}"
  outcomes["$status"]="$((last_count+1))"
done

printf "\n\n*** COMPLETE ***\n"
for code in "${!outcomes[@]}"; do
  echo "Exit $code: ${outcomes[$code]} times"
done

printf "\nOutput saved to %s\n" "$output"


