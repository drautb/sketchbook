#!/usr/bin/env sh

# Run this in the directory that contains all FS repos to properly set their
# git configuration.

set -eux

for d in $(find . -maxdepth 1 -type d); do
    if [ "$d" != "." ]; then
        cd "$d" && git config user.email drautb@familysearch.org && cd -
    fi
done
