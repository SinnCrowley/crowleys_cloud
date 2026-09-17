#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

CONFIG_FILE="config/config.json"
if [ ! -f "$CONFIG_FILE" ] && [ -f "config.json" ]; then
  CONFIG_FILE="config.json"
fi

echo "Starting Crowley's Cloud Server (base config + local overrides)."
echo "After startup, open http://localhost:<configured port> (default 8080)."

# Ensure binary is executable if present
if [ -f "./crowleys_cloud_server" ] && [ ! -x "./crowleys_cloud_server" ]; then
  chmod +x "./crowleys_cloud_server" 2>/dev/null || true
fi

# Find server binary
EXE_PATH=""
if [ -x "./crowleys_cloud_server" ]; then
  EXE_PATH="./crowleys_cloud_server"
elif [ -x "./build/Release/crowleys_cloud_server" ]; then
  EXE_PATH="./build/Release/crowleys_cloud_server"
elif [ -x "./build/crowleys_cloud_server" ]; then
  EXE_PATH="./build/crowleys_cloud_server"
elif [ -x "../build/Release/crowleys_cloud_server" ]; then
  EXE_PATH="../build/Release/crowleys_cloud_server"
elif [ -x "../build/crowleys_cloud_server" ]; then
  EXE_PATH="../build/crowleys_cloud_server"
elif [ -x "../../build/Release/crowleys_cloud_server" ]; then
  EXE_PATH="../../build/Release/crowleys_cloud_server"
elif [ -x "../../build/crowleys_cloud_server" ]; then
  EXE_PATH="../../build/crowleys_cloud_server"
else
  echo "[ERROR] crowleys_cloud_server executable not found!"
  exit 1
fi

if [ -f "$CONFIG_FILE" ]; then
  exec "$EXE_PATH" "$CONFIG_FILE"
else
  exec "$EXE_PATH"
fi
