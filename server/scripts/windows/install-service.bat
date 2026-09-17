@echo off
setlocal enabledelayedexpansion

echo =====================================================
echo Crowley's Cloud Server - Windows Background Setup
echo =====================================================
echo.

cd /d "%~dp0"
set "EXE_PATH="
set "APP_DIR="

if exist "%~dp0crowleys_cloud_server.exe" (
    for %%F in ("%~dp0crowleys_cloud_server.exe") do set "EXE_PATH=%%~fF"
    for %%F in ("%~dp0.") do set "APP_DIR=%%~fF"
) else if exist "%~dp0..\crowleys_cloud_server.exe" (
    for %%F in ("%~dp0..\crowleys_cloud_server.exe") do set "EXE_PATH=%%~fF"
    for %%F in ("%~dp0..") do set "APP_DIR=%%~fF"
) else if exist "%~dp0..\..\build\Release\crowleys_cloud_server.exe" (
    for %%F in ("%~dp0..\..\build\Release\crowleys_cloud_server.exe") do set "EXE_PATH=%%~fF"
    for %%F in ("%~dp0..\..") do set "APP_DIR=%%~fF"
) else if exist "%~dp0..\..\build\crowleys_cloud_server.exe" (
    for %%F in ("%~dp0..\..\build\crowleys_cloud_server.exe") do set "EXE_PATH=%%~fF"
    for %%F in ("%~dp0..\..") do set "APP_DIR=%%~fF"
)

if "!EXE_PATH!"=="" (
    echo [ERROR] crowleys_cloud_server.exe not found in "%~dp0" or parent directory.
    pause
    exit /b 1
)

echo Executable located at:
echo   !EXE_PATH!
echo Application directory:
echo   !APP_DIR!
echo.
echo Select an option:
echo   1. Install User Scheduled Task (Runs at user logon in background, no Admin required)
echo   2. Install System Scheduled Task (Runs at system boot in background, requires Administrator)
echo   3. Remove Background Task / Service
echo   4. Install via NSSM Service Wrapper (Requires Administrator and nssm.exe)
echo   5. Exit
echo.
set "OPTION="
set /p OPTION="Enter choice [1-5]: "

if "%OPTION%"=="1" (
    echo.
    echo Installing Scheduled Task 'CrowleysCloudServer' (on logon)...
    schtasks /create /tn "CrowleysCloudServer" /tr "\"!EXE_PATH!\"" /sc onlogon /rl limited /f
    if errorlevel 1 (
        echo [ERROR] Failed to create scheduled task.
    ) else (
        echo [SUCCESS] Scheduled task created. Server will start upon login.
        echo To start immediately: schtasks /run /tn "CrowleysCloudServer"
    )
) else if "%OPTION%"=="2" (
    echo.
    echo Installing Scheduled Task 'CrowleysCloudServer' (on boot)...
    net session >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Administrator privileges required. Please run this batch file as Administrator.
    ) else (
        schtasks /create /tn "CrowleysCloudServer" /tr "\"!EXE_PATH!\"" /sc onstart /ru "SYSTEM" /rl highest /f
        if errorlevel 1 (
            echo [ERROR] Failed to create system startup task.
        ) else (
            echo [SUCCESS] System startup task created. Server will start automatically on Windows boot.
            echo To start immediately: schtasks /run /tn "CrowleysCloudServer"
        )
    )
) else if "%OPTION%"=="3" (
    echo.
    echo Removing Background Task / Service 'CrowleysCloudServer'...
    schtasks /delete /tn "CrowleysCloudServer" /f >nul 2>&1
    if errorlevel 1 (
        echo [INFO] No scheduled task found.
    ) else (
        echo [SUCCESS] Scheduled task removed.
    )
    where nssm >nul 2>&1
    if not errorlevel 1 (
        nssm stop CrowleysCloudServer >nul 2>&1
        nssm remove CrowleysCloudServer confirm >nul 2>&1
        echo [INFO] NSSM service cleaned up if previously registered.
    )
) else if "%OPTION%"=="4" (
    echo.
    echo Installing via NSSM Service Manager...
    net session >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Administrator privileges required. Please run this batch file as Administrator.
    ) else (
        where nssm >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] 'nssm.exe' was not found in PATH.
            echo Download NSSM from https://nssm.cc/download and place nssm.exe in PATH or this directory.
            echo Manual command once installed:
            echo   nssm install CrowleysCloudServer "!EXE_PATH!"
            echo   nssm set CrowleysCloudServer AppDirectory "!APP_DIR!"
            echo   nssm start CrowleysCloudServer
        ) else (
            nssm install CrowleysCloudServer "!EXE_PATH!"
            nssm set CrowleysCloudServer AppDirectory "!APP_DIR!"
            nssm set CrowleysCloudServer DisplayName "Crowley's Cloud Server"
            nssm set CrowleysCloudServer Description "High performance self-hosted multi-server file cloud"
            nssm start CrowleysCloudServer
            if errorlevel 1 (
                echo [WARNING] NSSM service created but failed to start. Check Event Viewer.
            ) else (
                echo [SUCCESS] Service installed and started successfully via NSSM.
            )
        )
    )
) else (
    echo Exiting.
)

echo.
pause
