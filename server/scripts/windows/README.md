# Crowley's Cloud Server - Windows Setup Guide

## Quick Launch
Double-click `run.bat`. This will:
1. Load configuration from `config\config.json`.
2. Open your default web browser to the web interface (default: `http://localhost:8080`).
3. Run the Crowley's Cloud server in a console window.

## Running in the Background as a Service
You can run `crowleys_cloud_server.exe` in the background automatically when Windows boots or when you log in.

### Method 1: Scheduled Task (Native, Recommended)
Run `services\install-service.bat` (or `install-service.bat`):
- Option `1`: Run at user logon (no Administrator required).
- Option `2`: Run at system boot (requires Administrator, starts server even before login).

Command Prompt equivalents:
```cmd
rem Run at user logon (non-admin)
schtasks /create /tn "CrowleysCloudServer" /tr "\"C:\Full\Path\To\crowleys_cloud_server.exe\"" /sc onlogon /rl highest /f

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
