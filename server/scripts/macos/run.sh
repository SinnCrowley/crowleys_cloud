#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

PORT=8080
CONFIG_FILE="config/config.json"

if [ ! -f "$CONFIG_FILE" ] && [ -f "config.json" ]; then
  CONFIG_FILE="config.json"
fi

if [ -f "$CONFIG_FILE" ]; then
  EXTRACTED_PORT=$(grep -E -o '"port"[[:space:]]*:[[:space:]]*[0-9]+' "$CONFIG_FILE" | grep -E -o '[0-9]+' | head -n 1 || true)
  if [ -n "$EXTRACTED_PORT" ]; then
    PORT="$EXTRACTED_PORT"
  fi
fi

echo "==================================================="
echo "Starting Crowley's Cloud Server..."
echo "Configuration: $CONFIG_FILE"
echo "URL:           http://localhost:${PORT}"
echo "==================================================="

# Open default browser on macOS / Linux
if command -v open >/dev/null 2>&1; then
  (sleep 1 && open "http://localhost:${PORT}") &
elif command -v xdg-open >/dev/null 2>&1; then
  (sleep 1 && xdg-open "http://localhost:${PORT}") &
fi

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
