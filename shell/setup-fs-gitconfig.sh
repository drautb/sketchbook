#!/usr/bin/env sh

# Run this in the directory that contains all FS repos to properly set their
# git configuration.

set -eux

find . -type d -maxdepth 1 -exec sh -c '(cd {} && git config user.email drautb@familysearch.org)' ';'
