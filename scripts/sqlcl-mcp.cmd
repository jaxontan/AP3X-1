@echo off
setlocal

set "HARNESS_ROOT=%~dp0.."

if defined JAVA_HOME if not exist "%JAVA_HOME%\bin\java.exe" set "JAVA_HOME="
if not defined JAVA_HOME (
    for /d %%D in ("C:\Program Files\Microsoft\jdk-*") do set "JAVA_HOME=%%~fD"
)

if not defined SQLCL_BIN if exist "%HARNESS_ROOT%\tools\sqlcl\bin\sql.exe" set "SQLCL_BIN=%HARNESS_ROOT%\tools\sqlcl\bin\sql.exe"
if not defined SQLCL_BIN (
    for /f "delims=" %%S in ('where sql 2^>nul') do if not defined SQLCL_BIN set "SQLCL_BIN=%%S"
)

if not defined SQLCL_BIN (
    echo SQLcl not found. Run scripts\install-sqlcl.ps1 or set SQLCL_BIN. 1>&2
    exit /b 2
)

if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"

"%SQLCL_BIN%" -R 1 -mcp
exit /b %ERRORLEVEL%
