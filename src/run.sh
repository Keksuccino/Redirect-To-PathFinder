#!/bin/zsh
set -eu

SCRIPT_DIR=${0:A:h}
exec /usr/bin/osascript "$SCRIPT_DIR/redirect-finder-windows.applescript"
