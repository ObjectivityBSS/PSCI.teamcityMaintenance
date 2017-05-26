@echo off
pushd %~dp0
powershell -Command Import-Module "%~dp0\..\Objectivity.TeamcityMaintenance.psd1"; Initialize-TeamCityUpgrade
pause