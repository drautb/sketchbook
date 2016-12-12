#!/usr/bin/env sh

< "$HOME/.paas-portal" jq -r .accountCredentials\[\""$1"\"\].password | pbcopy
