# Crowley's Cloud Server - Windows Setup Guide (x64 & ARM64)

Crowley's Cloud Server for Windows is distributed as a native self-contained package for both **x64** (Intel/AMD) and **ARM64** (Windows on Arm / Qualcomm Snapdragon X Elite, etc.).

## Quick Launch
Double-click `run.bat`. This will:
1. Load configuration from `config\config.json`.
2. Initialize missing secrets on a fresh installation in `config\config.local.json`.
3. Run the Crowley's Cloud server in a console window.

After startup, open `http://localhost:8080` yourself (or your overridden port).
The launcher does not open a browser automatically. Extract the entire package
to a permanent writable user folder, not `Program Files`. Keep `public/` and
`config/` alongside the executable. Local settings belong in
`config\config.local.json`; omitted settings inherit the shipped defaults.

Video thumbnails require FFmpeg installed separately. Set `ffmpeg_binary` to
its full path for background tasks, or set `video_thumbs_enabled` to `false`.

## Updates and backups

Stop the server before replacing files. Back up `config\config.local.json`,
`data/` and `storage/` together. Extract the new archive into the same folder;
it excludes local config and runtime data. Preserve the generated keys. If
moving to a new directory, move these files too and recreate the background
task. Missing keys with existing data stop startup instead of regenerating keys.

## Running in the Background as a Service
You can run `crowleys_cloud_server.exe` in the background automatically when Windows boots or when you log in.

### Method 1: Scheduled Task (Native, Recommended)
Run `services\install-service.bat` (or `install-service.bat`):
- Option `1`: Run at user logon (no Administrator required).
- Option `2`: Run at system boot (requires Administrator, starts server even before login).

Command Prompt equivalents:
```cmd
rem Run at user logon (non-admin)
schtasks /create /tn "CrowleysCloudServer" /tr "\"C:\Full\Path\To\crowleys_cloud_server.exe\"" /sc onlogon /rl limited /f

rem Run at system startup (admin)
schtasks /create /tn "CrowleysCloudServer" /tr "\"C:\Full\Path\To\crowleys_cloud_server.exe\"" /sc onstart /ru "SYSTEM" /rl highest /f

rem Start task immediately
schtasks /run /tn "CrowleysCloudServer"

rem Stop and delete task
schtasks /delete /tn "CrowleysCloudServer" /f
```

### Method 2: NSSM Service Manager (Full Windows Service)
Standard console applications require a service wrapper like [NSSM](https://nssm.cc/) to communicate with the Windows Service Control Manager:
```cmd
nssm install CrowleysCloudServer "C:\Full\Path\To\crowleys_cloud_server.exe" "C:\Full\Path\To\config\config.json"
nssm set CrowleysCloudServer AppDirectory "C:\Full\Path\To"
nssm set CrowleysCloudServer DisplayName "Crowley's Cloud Server"
nssm start CrowleysCloudServer
```

To stop and remove the NSSM service:
```cmd
nssm stop CrowleysCloudServer
nssm remove CrowleysCloudServer confirm
```
