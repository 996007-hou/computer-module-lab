@echo off
setlocal
cd /d "%~dp0"
set "TEMP=%~dp0runtime\temp"
set "TMP=%~dp0runtime\temp"
set "APPDATA=%~dp0runtime\appdata"
set "LOCALAPPDATA=%~dp0runtime\localappdata"
if not exist "%~dp0tools\Godot_v4.4.1-stable_win64_console.exe" (
 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ensure_godot.ps1"
 if errorlevel 1 exit /b 1
)
for %%D in ("%TEMP%" "%APPDATA%" "%LOCALAPPDATA%") do (
 if not exist "%%~D" (
  mkdir "%%~D" || exit /b 1
 )
)
for %%T in (smoke paging_test schedule_test banker_test replacement_test invariants playback_test semaphore_test chapter_labs_test) do (
 "%~dp0tools\Godot_v4.4.1-stable_win64_console.exe" --headless --path . --script "res://tests/%%T.gd"
 if errorlevel 1 exit /b 1
)
echo All checks passed.
endlocal
