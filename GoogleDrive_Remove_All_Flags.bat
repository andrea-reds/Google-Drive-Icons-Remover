@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Executes Hide_Flags_GoogleDrive.bat twice with distinct ROOT/BACKUP, using /norestart
rem Explorer is restarted only once, ONLY if at least one call
rem deleted at least one default VALUE (not the whole key)
rem Run as administrator; place the BAT files in the same folder

rem ================= DEFAULT CONFIGURATION =================
set "ROOT1=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"
set "BACKUP1=%ProgramData%\GoogleDriveOverlayBackup"
set "ROOT2=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"
set "BACKUP2=%ProgramData%\GoogleDriveOverlayBackup_WOW6432Node"
rem ==================================================

rem GoogleDrive_Remove_All_Flags "ROOT1" "BACKUP1" "ROOT2" "BACKUP2"
if not "%~1"=="" (
    if "%~4"=="" goto :HELP_ERROR
    set "ROOT1=%~1"
    set "BACKUP1=%~2"
    set "ROOT2=%~3"
    set "BACKUP2=%~4"
)
if not "%~5"=="" goto :HELP_ERROR

if not exist "%~dp0Hide_Flags_GoogleDrive.bat" (
    echo ERROR: file Hide_Flags_GoogleDrive.bat not found
    exit /b 1
)
if /i "!ROOT1!"=="!ROOT2!" (
    echo ERROR: ROOT1 e ROOT2 must be different
    exit /b 1
)
if /i "!BACKUP1!"=="!BACKUP2!" (
    echo ERROR: BACKUP1 e BACKUP2 must be different
    exit /b 1
)

fltmc >nul 2>&1
if errorlevel 1 (
    echo ERROR: run as administrator
    exit /b 1
)

set "ANY_CHANGE=0"
set "ANY_ERROR=0"

echo === FIRST CALL ===
call "%~dp0Hide_Flags_GoogleDrive.bat" "!ROOT1!" "!BACKUP1!" /norestart
set "RC1=!ERRORLEVEL!"
if "!RC1!"=="2" set "ANY_CHANGE=1"
if "!RC1!"=="3" (
    set "ANY_CHANGE=1"
    set "ANY_ERROR=1"
)
if "!RC1!"=="1" set "ANY_ERROR=1"
if !RC1! GTR 3 set "ANY_ERROR=1"

echo.
echo === SECOND CALL ===
call "%~dp0Hide_Flags_GoogleDrive.bat" "!ROOT2!" "!BACKUP2!" /norestart
set "RC2=!ERRORLEVEL!"
if "!RC2!"=="2" set "ANY_CHANGE=1"
if "!RC2!"=="3" (
    set "ANY_CHANGE=1"
    set "ANY_ERROR=1"
)
if "!RC2!"=="1" set "ANY_ERROR=1"
if !RC2! GTR 3 set "ANY_ERROR=1"

echo.
echo === FINAL RESULT ===
echo Call code 1: !RC1!
echo Call code 2: !RC2!

if "!ANY_CHANGE!"=="1" (
    echo At least one change detected: restarting Explorer ONLY ONCE
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    start "" "%SystemRoot%\explorer.exe"
) else (
    echo No changes detected: Explorer will NOT be restarted
)

if "!ANY_ERROR!"=="1" (
    echo WARNING: at least one call reported errors
    exit /b 1
)
exit /b 0

:HELP_ERROR
echo ERROR: all 4 arguments are required, or none.
echo Uso: %~nx0 "ROOT1" "BACKUP1" "ROOT2" "BACKUP2"
exit /b 1
