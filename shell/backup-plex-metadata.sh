#!/usr/bin/env bash

set -eux

PLEX_HOME="/var/lib/plexmediaserver/Library/Application\ Support/Plex\ Media\ Server"
BACKUPS="$HOME/plex-mirror/backups"

mkdir -p "$BACKUPS/db"

# Sync DB backups
rsync -aP --delete --exclude='*.db' --exclude='*.db-shm' --exclude='*.db-wal' pi@minibian:"$PLEX_HOME/Plug-in\ Support/Databases/" "$BACKUPS/db/"

# Sync Preferences file
rsync -aP pi@minibian:"$PLEX_HOME/Preferences.xml" "$BACKUPS"




