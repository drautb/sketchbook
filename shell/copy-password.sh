#!/usr/bin/env sh

cat ~/$1-us-east-1-env | grep AWS_PASSWORD | sed -E 's/.*="(.*)"$/\1/g' | pbcopy
