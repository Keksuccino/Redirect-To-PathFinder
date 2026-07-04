#!/bin/zsh
set -eu
set -o pipefail

LABEL="com.keksuccino.redirect-to-pathfinder"
APP_NAME="Redirect-To-PathFinder"
APP_SUPPORT_DIR="$HOME/Library/Application Support/$APP_NAME"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

/bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
/bin/rm -f "$LAUNCH_AGENT_PATH"
/bin/rm -rf "$APP_SUPPORT_DIR"

printf '%s\n' "Uninstalled $APP_NAME."
