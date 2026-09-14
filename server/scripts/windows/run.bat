@echo off
setlocal enabledelayedexpansion
title Crowley's Cloud Server

echo ===================================================
echo Starting Crowley's Cloud Server...
echo ===================================================

cd /d "%~dp0"

set "PORT=8080"
set "CONFIG_FILE=config\config.json"

if not exist "!CONFIG_FILE!" (
    if exist "config.json" (
        set "CONFIG_FILE=config.json"
    )
)

if exist "!CONFIG_FILE!" (
    for /f "tokens=2 delims=:, " %%a in ('findstr /i "\"port\"" "!CONFIG_FILE!" 2^>nul') do (
        set "PORT=%%~a"
    )
)

echo Configuration: !CONFIG_FILE!
echo URL:           http://localhost:!PORT!
echo.

rem Launch default web browser to the server interface
start "" "http://localhost:!PORT!"

rem Locate server binary
set "EXE_CMD="
if exist "crowleys_cloud_server.exe" (
    set "EXE_CMD=crowleys_cloud_server.exe"
) else if exist "Release\crowleys_cloud_server.exe" (
    set "EXE_CMD=Release\crowleys_cloud_server.exe"
) else if exist "build\Release\crowleys_cloud_server.exe" (
    set "EXE_CMD=build\Release\crowleys_cloud_server.exe"
) else if exist "build\crowleys_cloud_server.exe" (
    set "EXE_CMD=build\crowleys_cloud_server.exe"
) else if exist "..\build\Release\crowleys_cloud_server.exe" (
    set "EXE_CMD=..\build\Release\crowleys_cloud_server.exe"
) else if exist "..\build\crowleys_cloud_server.exe" (
    set "EXE_CMD=..\build\crowleys_cloud_server.exe"
) else if exist "..\..\build\Release\crowleys_cloud_server.exe" (
    set "EXE_CMD=..\..\build\Release\crowleys_cloud_server.exe"
) else if exist "..\..\build\crowleys_cloud_server.exe" (
    set "EXE_CMD=..\..\build\crowleys_cloud_server.exe"
) else (
    echo [ERROR] crowleys_cloud_server.exe was not found!
    echo Please ensure the executable is in the same directory as this script.
    pause
    exit /b 1
)

rem Execute the server
if exist "!CONFIG_FILE!" (
    "!EXE_CMD!" "!CONFIG_FILE!"
) else (
    "!EXE_CMD!"
)

if errorlevel 1 (
    echo.
    echo [ERROR] Server terminated with error code !errorlevel!.
    pause
)
