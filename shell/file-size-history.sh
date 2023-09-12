#!/usr/bin/env bash

#set -eux

# Hacky script to print the size of a file throughout the git history.
# Intended to be piped into ttyplot. Compatible with git-lfs.
#
# file-size-history.sh "MyGrowingFile.bin" | ttyplot

filename="$1"

for commit in $(git rev-list HEAD | tac); do
  path="$(git ls-tree -r --name-only $commit | grep $filename | head -n1)"
  size="$(git show $commit:$path | grep "size" | awk '{ print $2 }')"
  # https://stackoverflow.com/a/2704760/1062562
  if [ -z "${size##*[!0-9]*}" ]; then
    size="$(git ls-tree -r -l $commit $path | awk '{ print $4 }')"
  fi
  echo "$size"
done
