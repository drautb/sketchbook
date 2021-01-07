#!/usr/bin/env sh

REPO_NAME="$1"

git clone git@github.com:fs-webdev/$REPO_NAME.git

(cd $REPO_NAME && git config user.email drautb@familysearch.org)

