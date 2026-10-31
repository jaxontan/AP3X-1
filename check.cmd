@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\check-prereqs.ps1" %*
set "CODE=%errorlevel%"
if "%~1"=="" pause
exit /b %CODE%
