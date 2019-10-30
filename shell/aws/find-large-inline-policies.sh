#!/usr/bin/env bash

set -e

function countPolicies {
  [[ "$1" =~ ^ps-|^paas- ]] || return

  policy_count=$(aws iam list-role-policies --role-name "$1" | jq '.PolicyNames | length')

  if (( policy_count > 10 )); then
    echo "$1 - $policy_count"
  fi
}

export -f countPolicies

aws iam list-roles | jq -r '.Roles[].RoleName' | parallel countPolicies
