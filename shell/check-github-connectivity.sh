#!/usr/bin/env bash

COUNT=$1

GOOD=0
BAD=0

for _ in $(seq 1 "$COUNT"); do

  nc -z -w 1 github.com 22
  result=$?
  if [ $result -eq 0 ]; then
    GOOD=$((GOOD + 1))
  else
    BAD=$((BAD + 1))
  fi

done

good_pct=$((GOOD * 100 / COUNT))
bad_pct=$((BAD * 100 / COUNT))


echo "$GOOD/$COUNT connection attempts succeeded. ($good_pct%)"
echo "$BAD/$COUNT connection attempts failed. ($bad_pct%)"

