@echo off
setlocal
cd /d "%~dp0" || goto error
set "TEMP=%~dp0runtime\temp"
set "TMP=%~dp0runtime\temp"
set "APPDATA=%~dp0runtime\appdata"
set "LOCALAPPDATA=%~dp0runtime\localappdata"
if not exist "%~dp0tools\Godot_v4.4.1-stable_win64.exe" goto error
if not exist "%TEMP%" mkdir "%TEMP%" || goto error
if not exist "%APPDATA%" mkdir "%APPDATA%" || goto error
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%" || goto error
"%~dp0tools\Godot_v4.4.1-stable_win64.exe" --path .
if errorlevel 1 goto error
endlocal
exit /b 0
:error
echo.
echo The application could not start. Check that the project folder and tools are complete.
pause
exit /b 1
