@echo off
pushd %~dp0
powershell -File Restore-TeamCityServer.ps1
pause