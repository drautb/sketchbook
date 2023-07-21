#!/usr/bin/env bash
#
# gsr - git status recursive
# Run git-status in all git repos that are subdirectories of cwd
# and print summary output. Excludes several common ignorable
# directories for brazil workspaces.


while IFS='' read -r -d '' d; do
  pushd "$d/../" > /dev/null

  cwd="$(basename $(pwd))"
  if [ -n "$(git status --porcelain)" ]; then
    echo -e "$cwd - \033[31mDIRTY\033[0m"
  else
    echo -e "$cwd - \033[32mClean\033[0m"
  fi

  popd > /dev/null
done < <(find . -name env -prune -o -name build -prune -o -name .bemol -prune -o -name .git -type d -print0)
