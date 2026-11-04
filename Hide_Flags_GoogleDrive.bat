@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Google Drive: modifies overlay registry entries
rem Usage: Hide_Flag_GoogleDrive.bat ["ROOT"] ["BACKUP"] [/norestart]
rem        Hide_Flag_GoogleDrive.bat restore ["ROOT"] ["BACKUP"] [/norestart]
rem /norestart: does NOT restart Explorer and returns:
rem   0 = no changes, no errors
rem   1 = no changes, at least one error
rem   2 = at least one value modified, no errors
rem   3 = at least one value modified, at least one error
rem Without /norestart, it retains the previous behavior: 0=OK, 1=error
rem Requires running as administrator. Avoid paths containing !

set "ROOT=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers"
set "BACKUP=%ProgramData%\GoogleDriveOverlayBackup"
set "MODE=hide"
set "NORESTART=0"

if /i "%~1"=="/?" goto :HELP
if /i "%~1"=="restore" (
    set "MODE=restore"
    shift
)

if not "%~1"=="" set "ROOT=%~1"
if not "%~2"=="" set "BACKUP=%~2"
if /i "%~3"=="/norestart" (
    set "NORESTART=1"
) else (
    if not "%~3"=="" goto :HELP_ERROR
)
if not "%~4"=="" goto :HELP_ERROR

fltmc >nul 2>&1
if errorlevel 1 (
    echo ERROR: run as administrator
    exit /b 1
)

if /i "!MODE!"=="restore" goto :restore

reg query "!ROOT!" >nul 2>&1
if errorlevel 1 (
    echo ERROR: ROOT does not exist or is inaccessible: !ROOT!
    exit /b 1
)

if not exist "!BACKUP!" mkdir "!BACKUP!" >nul 2>&1
if not exist "!BACKUP!" (
    echo ERROR: cannot create the BACKUP folder: !BACKUP!
    exit /b 1
)

set /a FOUND=0,CHANGED=0,ERRORS=0

echo ROOT   = !ROOT!
echo BACKUP = !BACKUP!
echo.

rem Filter
for /f "delims=" %%K in ('reg query "!ROOT!" 2^>nul ^| findstr /i /r "GoogleDrive.*OverlayIconHandler$"') do (
    set /a FOUND+=1 >nul
    for %%N in ("%%K") do set "NAME=%%~nxN"
    set "NAME=!NAME: =!"

    rem Proceed only if the default value contains the character { (CLSID).
    reg query "%%K" /ve 2>nul | findstr /c:"{" >nul
    if not errorlevel 1 (
        set "READY=1"
        if not exist "!BACKUP!\!NAME!.reg" (
            reg export "%%K" "!BACKUP!\!NAME!.reg" >nul 2>&1
            if errorlevel 1 (
                echo ERROR: backup failed for !NAME!.
                set "READY=0"
                set /a ERRORS+=1 >nul
            )
        )
        if "!READY!"=="1" (
            rem Delete only the default VALUE, not the key.
            reg delete "%%K" /ve /f >nul 2>&1
            if errorlevel 1 (
                echo ERROR: modification failed for !NAME!.
                set /a ERRORS+=1 >nul
            ) else (
                echo Disabled: !NAME!
                set /a CHANGED+=1 >nul
            )
        )
    )
)

if !FOUND! EQU 0 echo No Google Drive manager matching the filter.
if !CHANGED! GTR 0 (
    echo Default values removed: !CHANGED!.
    if !NORESTART! EQU 0 (
        echo Restarting File Explorer...
        call :RESTART_EXPLORER
    ) else (
        echo Explorer restart deferred to the calling script.
    )
) else (
    echo No changes required.
)

if !NORESTART! EQU 1 (
    if !ERRORS! GTR 0 (
        if !CHANGED! GTR 0 (exit /b 3) else (exit /b 1)
    ) else (
        if !CHANGED! GTR 0 (exit /b 2) else (exit /b 0)
    )
)
if !ERRORS! GTR 0 exit /b 1
exit /b 0

:restore
if not exist "!BACKUP!\*.reg" (
    echo ERROR: no backup .reg found in: !BACKUP!
    exit /b 1
)
echo ROOT   = !ROOT!
echo BACKUP = !BACKUP!

set /a RESTORED=0,ERRORS=0
for %%F in ("!BACKUP!\*.reg") do (
    reg import "%%~fF" >nul 2>&1
    if errorlevel 1 (
        echo ERROR: import failed: %%~nxF
        set /a ERRORS+=1 >nul
    ) else (
        echo restoreto: %%~nxF
        set /a RESTORED+=1 >nul
    )
)
if !RESTORED! GTR 0 (
    if !NORESTART! EQU 0 (
        echo Restarting File Explorer...
        call :RESTART_EXPLORER
    ) else (
        echo Explorer restart deferred to the calling script.
    )
)
if !NORESTART! EQU 1 (
    if !ERRORS! GTR 0 (
        if !RESTORED! GTR 0 (exit /b 3) else (exit /b 1)
    ) else (
        if !RESTORED! GTR 0 (exit /b 2) else (exit /b 0)
    )
)
if !ERRORS! GTR 0 exit /b 1
exit /b 0

:RESTART_EXPLORER
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" "%SystemRoot%\explorer.exe"
exit /b 0

:HELP
echo Usage:
echo   %~nx0 ["ROOT"] ["BACKUP"] [/norestart]
echo   %~nx0 restore ["ROOT"] ["BACKUP"] [/norestart]
exit /b 0

:HELP_ERROR
echo ERROR: invalid parameters.
echo Utilizzo: %~nx0 [restore] ["ROOT"] ["BACKUP"] [/norestart]
exit /b 1
