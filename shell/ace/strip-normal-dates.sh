#!/usr/bin/env bash

target_file=$1

grep -v -i -E \
  -e "\"text\":\"about\s+\d{4}\"" \
  -e "\"text\":\"\d{1,2}\s+\w{3}\s+\d{4}\"" \
  -e "\"text\":\"\w{3}\s+\d{1,2},\s+\d{4}\"" \
  -e "\"text\":\"\d{1,2}\s+[january|february|march|april|may|june|july|august|september|october|november|december]\s+\d{4}\"" \
  "$target_file"
