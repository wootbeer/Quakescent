@echo off
rem Quakescent launcher: see tools\launcher.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\launcher.ps1" %*
if errorlevel 1 pause
