@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launch_client.ps1" -Presentation 3d -Quality recommended
if errorlevel 1 pause
endlocal
