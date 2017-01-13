#!/usr/bin/env sh

password=$(< "$HOME/.paas-portal" jq -r .accountCredentials\[\""$1"\"\].password)
system=$(uname -s)

if [ "$system" = "Darwin" ]; then
  echo "$password" | pbcopy
elif [ "$system" = "Linux" ]; then
  copyq add "$password"
  copyq copy "$password"
fi
