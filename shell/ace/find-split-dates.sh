#!/usr/bin/env bash

file="$1"

function count_date_tokens {
  pos="$1"
  < "$file" jq "[.regions[].lines[].tokens[] | select(.type == \"DATE\" and .position == \"$pos\")] | length"
}

printf "Date Token Counts for '%s':\n" "$file"
printf "UNIT:  %s\n" "$(count_date_tokens "U")"
printf "BEGIN: %s\n" "$(count_date_tokens "B")"
printf "INTER: %s\n" "$(count_date_tokens "I")"
printf "END:   %s\n" "$(count_date_tokens "E")"
