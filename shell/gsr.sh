#!/usr/bin/env bash
#
# gsr - git status recursive
# Run git-status in all git repos that are subdirectories of cwd
# and print summary output. Excludes several common ignorable
# directories for brazil workspaces.

# TODO: Also show if it's n commits ahead/behind remote (or even)
while IFS='' read -r -d '' d; do
  pushd "$d/../" > /dev/null

  output="$(basename $(pwd)) (\033[34m$(git branch --show-current)\033[0m)"
  if [ -n "$(git status --porcelain)" ]; then
    output="$output - \033[31mDIRTY\033[0m"
  else
    output="$output - \033[32mCLEAN\033[0m"
  fi

  gs_long="$(git status)"
  if [[ "$gs_long" =~ "Your branch is up to date with" ]]; then
    output="$output - Up to date"
  elif [[ "$gs_long" =~ "Your branch is behind" ]]; then
    output="$output - \033[33mBEHIND by "$(echo "$gs_long" | tr -dc '0-9')"\033[0m"
  elif [[ "$gs_long" =~ "Your branch is ahead" ]]; then
    output="$output - \033[35mAHEAD by "$(echo "$gs_long" | tr -dc '0-9')"\033[0m"
  fi

  echo -e "$output"

  popd > /dev/null
done < <(find . -name env -prune -o -name build -prune -o -name .bemol -prune -o -name .git -type d -print0)
