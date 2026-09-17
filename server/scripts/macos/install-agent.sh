#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -x "$APP_DIR/crowleys_cloud_server" ] || [ ! -f "$APP_DIR/config/config.json" ]; then
  echo "Run this script from services/ inside the extracted release."
  exit 1
fi
mkdir -p "$HOME/Library/LaunchAgents" "$APP_DIR/logs"
PLIST="$HOME/Library/LaunchAgents/com.crowleyscloud.server.plist"
cp "$APP_DIR/services/com.crowleyscloud.server.plist" "$PLIST"
/usr/bin/plutil -replace ProgramArguments.0 -string "$APP_DIR/crowleys_cloud_server" "$PLIST"
/usr/bin/plutil -replace ProgramArguments.1 -string "$APP_DIR/config/config.json" "$PLIST"
/usr/bin/plutil -replace StandardOutPath -string "$APP_DIR/logs/launchd.stdout.log" "$PLIST"
/usr/bin/plutil -replace StandardErrorPath -string "$APP_DIR/logs/launchd.stderr.log" "$PLIST"
USER_DOMAIN="gui/$(id -u)"
launchctl bootout "$USER_DOMAIN/com.crowleyscloud.server" 2>/dev/null || true
launchctl bootstrap "$USER_DOMAIN" "$PLIST"
echo "Installed user LaunchAgent using $APP_DIR. Keep this folder in place."
