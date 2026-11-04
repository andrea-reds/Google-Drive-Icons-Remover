@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Restores Google Drive overlay default values from two backups
rem Usage: GoogleDrive_Restore_All_Flags.bat ["ROOT1" "BACKUP1" "ROOT2" "BACKUP2"]
rem Requires Hide_Flags_GoogleDrive.bat with support for "restore" and /norestart
rem Run as administrator
rem Paths must not contain the ! character (delayed expansion)

rem ======= CONFIGURATION ====================================================
set "ROOT1=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"
set "BACKUP1=%ProgramData%\GoogleDriveOverlayBackup"
set "ROOT2=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"
set "BACKUP2=%ProgramData%\GoogleDriveOverlayBackup_WOW6432Node"
rem ==========================================================================

rem Optional: overrides all four variables from the command line
if not "%~1"=="" (
    if "%~2"=="" goto :USAGE_ERROR
    if "%~3"=="" goto :USAGE_ERROR
    if "%~4"=="" goto :USAGE_ERROR
    set "ROOT1=%~1"
    set "BACKUP1=%~2"
    set "ROOT2=%~3"
    set "BACKUP2=%~4"
)
if not "%~5"=="" goto :USAGE_ERROR

if not exist "%~dp0Hide_Flags_GoogleDrive.bat" (
    echo ERROR: Hide_Flags_GoogleDrive.bat is missing from the same folder
    exit /b 1
)

if /i "!BACKUP1!"=="!BACKUP2!" (
    echo ERROR: BACKUP1 and BACKUP2 must be distinct folders
    exit /b 1
)

fltmc >nul 2>&1
if errorlevel 1 (
    echo ERROR: run as administrator
    exit /b 1
)

rem Check that both backup groups exist BEFORE importing either one.
if not exist "!BACKUP1!\*.reg" (
    echo ERROR: no .reg file found in the first backup: !BACKUP1!
    exit /b 1
)
if not exist "!BACKUP2!\*.reg" (
    echo ERROR: no .reg file found in the second backup: !BACKUP2!
    exit /b 1
)

echo ALL .reg files present in the backup folders will be imported
echo.
echo ===== FIRST RESTORE =====
call "%~dp0Hide_Flags_GoogleDrive.bat" restore "!ROOT1!" "!BACKUP1!" /norestart
set "RC1=!ERRORLEVEL!"

echo.
echo ===== SECOND RESTORE =====
call "%~dp0Hide_Flags_GoogleDrive.bat" restore "!ROOT2!" "!BACKUP2!" /norestart
set "RC2=!ERRORLEVEL!"

rem Child exit codes: 0 = no restore; 1 = error without restore;
rem 2 = at least one successful import; 3 = successful imports with errors.
set "ANY_RESTORED=0"
set "ANY_ERROR=0"
if "!RC1!"=="2" set "ANY_RESTORED=1"
if "!RC1!"=="3" (set "ANY_RESTORED=1" & set "ANY_ERROR=1")
if "!RC1!"=="1" set "ANY_ERROR=1"
if not "!RC1!"=="0" if not "!RC1!"=="1" if not "!RC1!"=="2" if not "!RC1!"=="3" set "ANY_ERROR=1"
if "!RC2!"=="2" set "ANY_RESTORED=1"
if "!RC2!"=="3" (set "ANY_RESTORED=1" & set "ANY_ERROR=1")
if "!RC2!"=="1" set "ANY_ERROR=1"
if not "!RC2!"=="0" if not "!RC2!"=="1" if not "!RC2!"=="2" if not "!RC2!"=="3" set "ANY_ERROR=1"

echo.
echo ===== FINAL RESULT =====
echo First restore exit code : !RC1!
echo Second restore exit code: !RC2!
if "!ANY_RESTORED!"=="1" (
    echo At least one file imported: restart Explorer only once.
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    start "" "%SystemRoot%\explorer.exe"
) else (
    echo No files imported: Explorer is NOT restarted.
)

if "!ANY_ERROR!"=="1" (
    echo WARNING: one or both restores reported errors
    exit /b 1
)

echo Operation completed.
exit /b 0

:USAGE_ERROR
echo ERROR: all 4 arguments are required, or none.
echo Uso: %~nx0 "ROOT1" "BACKUP1" "ROOT2" "BACKUP2"
exit /b 1
