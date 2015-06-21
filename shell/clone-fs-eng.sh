#!/usr/bin/env sh

REPO_NAME="$1"

git clone git@github.com:fs-eng/$REPO_NAME.git

(cd $REPO_NAME && git config user.email drautb@familysearch.org)

