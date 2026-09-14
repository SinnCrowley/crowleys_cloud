# Crowley's Cloud Server - macOS Setup Guide

## Quick Launch
Execute `run.sh` in the terminal or double-click it in Finder:
```bash
./run.sh
```
This will:
1. Load configuration from `config/config.json`.
2. Open your default browser to `http://localhost:8080`.
3. Launch `crowleys_cloud_server`.

## Running in the Background via launchd
macOS manages background daemons and user agents through `launchd`.

### Step 1: Install Binary and Configuration
```bash
sudo cp crowleys_cloud_server /usr/local/bin/
sudo mkdir -p /usr/local/etc/crowleys_cloud
sudo cp config/config.json /usr/local/etc/crowleys_cloud/
```

### Step 2: Install LaunchAgent (User Session)
To run automatically whenever you log in:
```bash
cp services/com.crowleyscloud.server.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.crowleyscloud.server.plist
```

To stop or unload:
```bash
launchctl unload ~/Library/LaunchAgents/com.crowleyscloud.server.plist
```

Logs are written to:
- Output: `/tmp/crowleys_cloud_server.log`
- Errors: `/tmp/crowleys_cloud_server_err.log`
