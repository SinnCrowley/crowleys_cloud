@echo off
setlocal DisableDelayedExpansion
title Crowley's Cloud Server
cd /d "%~dp0"
set "CONFIG_FILE=config\config.json"
if not exist "%CONFIG_FILE%" if exist "config.json" set "CONFIG_FILE=config.json"
echo Starting Crowley's Cloud Server (base config + local overrides).
echo After startup, open http://localhost:YOUR_PORT (default 8080).
for %%F in ("crowleys_cloud_server.exe" "Release\crowleys_cloud_server.exe" "build\Release\crowleys_cloud_server.exe" "build\crowleys_cloud_server.exe" "..\build\Release\crowleys_cloud_server.exe" "..\build\crowleys_cloud_server.exe" "..\..\build\Release\crowleys_cloud_server.exe" "..\..\build\crowleys_cloud_server.exe") do if exist "%%~F" (
    set "EXE_CMD=%%~F"
    goto run
)
echo [ERROR] crowleys_cloud_server.exe was not found.
pause
exit /b 1
:run
if exist "%CONFIG_FILE%" (
    "%EXE_CMD%" "%CONFIG_FILE%"
) else (
    "%EXE_CMD%"
)
set "SERVER_EXIT=%ERRORLEVEL%"
if not "%SERVER_EXIT%"=="0" (
    echo [ERROR] Server terminated with error code %SERVER_EXIT%.
    pause
)
exit /b %SERVER_EXIT%
