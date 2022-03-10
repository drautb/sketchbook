#!/usr/bin/env sh

ORG_NAME="$1"
REPO_NAME="$2"

git clone git@github.com:$ORG_NAME/$REPO_NAME.git

(cd $REPO_NAME && git config user.email drautb@familysearch.org)

