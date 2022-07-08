#!/usr/bin/env bash

# Generates a summary of record size information based on two input files.

for gid in $(jq -r '.result.groupId' recordAnalysisSummary.json); do
  tiny_count=$(jq -r --arg gid "$gid" '.result | select(.groupId == $gid).count' recordAnalysisSummary.json)
  jq -r --arg gid "$gid" '.result | select(.groupId == $gid)._raw' groupAnalysis.json | jq -rc --arg tiny_count $tiny_count '. + {recordCountLessThan1MP: $tiny_count | tonumber}'
done


