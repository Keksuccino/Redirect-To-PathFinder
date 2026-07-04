#!/bin/zsh
set -eu
set -o pipefail

LABEL="com.keksuccino.redirect-to-pathfinder"
APP_NAME="Redirect-To-PathFinder"
SOURCE_DIR=${0:A:h:h}
APP_SUPPORT_DIR="$HOME/Library/Application Support/$APP_NAME"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_OUT_PATH="$HOME/Library/Logs/$LABEL.out.log"
LOG_ERR_PATH="$HOME/Library/Logs/$LABEL.err.log"
RUN_SCRIPT_PATH="$APP_SUPPORT_DIR/run.sh"

xml_escape() {
    /usr/bin/sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g"
}

require_path_finder() {
    if ! /usr/bin/osascript -e 'id of application "Path Finder"' >/dev/null 2>&1; then
        printf '%s\n' "Path Finder was not found. Install Path Finder first, then rerun this installer." >&2
        exit 1
    fi
}

write_launch_agent() {
    local run_script_xml log_out_xml log_err_xml

    run_script_xml=$(printf '%s' "$RUN_SCRIPT_PATH" | xml_escape)
    log_out_xml=$(printf '%s' "$LOG_OUT_PATH" | xml_escape)
    log_err_xml=$(printf '%s' "$LOG_ERR_PATH" | xml_escape)

    /bin/mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

    /bin/cat > "$LAUNCH_AGENT_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$run_script_xml</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$log_out_xml</string>
  <key>StandardErrorPath</key>
  <string>$log_err_xml</string>
</dict>
</plist>
PLIST

    /usr/bin/plutil -lint "$LAUNCH_AGENT_PATH" >/dev/null
}

install_files() {
    /bin/mkdir -p "$APP_SUPPORT_DIR"
    /usr/bin/install -m 755 "$SOURCE_DIR/src/run.sh" "$RUN_SCRIPT_PATH"
    /usr/bin/install -m 644 "$SOURCE_DIR/src/redirect-finder-windows.applescript" "$APP_SUPPORT_DIR/redirect-finder-windows.applescript"
    /usr/bin/osacompile -o /tmp/redirect-to-pathfinder-check.scpt "$APP_SUPPORT_DIR/redirect-finder-windows.applescript"
}

load_launch_agent() {
    /bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
    /bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$LAUNCH_AGENT_PATH"
    /bin/launchctl kickstart -k "gui/$(/usr/bin/id -u)/$LABEL"
}

require_path_finder
install_files
write_launch_agent
load_launch_agent

printf '%s\n' "Installed and started $APP_NAME."
printf '%s\n' "LaunchAgent: $LAUNCH_AGENT_PATH"
printf '%s\n' "Helper files: $APP_SUPPORT_DIR"
