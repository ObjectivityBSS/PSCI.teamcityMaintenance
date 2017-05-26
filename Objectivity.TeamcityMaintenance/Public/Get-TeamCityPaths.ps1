<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Get-TeamCityPaths {
    <#
    .SYNOPSIS
    Gets paths to local TeamCity instance, basing on environment variables and convention.

    .EXAMPLE
    Get-TeamCityPaths
    #>   

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $teamCityDataDir = [Environment]::GetEnvironmentVariable("TEAMCITY_DATA_PATH", "Machine")
    if (!$teamCityDataDir) {
        throw "No environment variable named TEAMCITY_DATA_PATH. Please ensure TeamCity has been installed. For restore help please run Get-TeamCityRestorePlan."
    }
    if (!(Test-Path -LiteralPath $teamCityDataDir)) {
        throw "Cannot access directory (taken from env:TEAMCITY_DATA_PATH) at: '$teamCityDataDir'"
    }
    if ($teamCityDataDir -ieq 'C:\ProgramData\JetBrains\TeamCity') {
        throw "TeamCity data directory has been found at default location ('C:\ProgramData\JetBrains\TeamCity'). Please reinstall according to the convention (X:\TeamCity and X:\TeamCityData). For restore help please run Get-TeamCityRestorePlan."
    }
    Write-Log -Info "TeamCity data directory found at '$teamCityDataDir'"

    $teamCityServerDir = $teamCityDataDir -replace "data", ""
    if (!(Test-Path -LiteralPath $teamCityServerDir)) {
        throw "Cannot access TeamCity home directory derived from convention (env:TEAMCITY_DATA_PATH without 'data') at: '$teamCityServerDir'. Please reinstall according to the convention (X:\TeamCity and X:\TeamCityData). For restore help please run Get-TeamCityRestorePlan."
    }
    $teamCityCheckFile = Join-Path -Path $teamCityServerDir -ChildPath "jre"
    if (!(Test-Path -LiteralPath $teamCityCheckFile)) {
        throw "Cannot access TeamCity jre directory at: '$teamCityCheckFile'. Please ensure TeamCity has been installed. For restore help please run Get-TeamCityRestorePlan."
    }
    $teamCityCheckFile = Join-Path -Path $teamCityServerDir -ChildPath "bin\maintainDB.cmd"
    if (!(Test-Path -LiteralPath $teamCityCheckFile)) {
        throw "Cannot access TeamCity file at: '$teamCityCheckFile'. Please ensure TeamCity has been installed. For restore help please run Get-TeamCityRestorePlan."
    }
    Write-Log -Info "TeamCity home directory found at '$teamCityServerDir'"

    return [PSCustomObject]@{
        TeamCityDataDir = $teamCityDataDir;
        TeamCityServerDir = $teamCityServerDir;
        TeamCityBackupDir = @($teamCityDataDir, "backup") -join '\';
        TeamCityConfigDir = @($teamCityDataDir, "config") -join '\';
        TeamCityArtifactsRelativeDir = @("system", "artifacts") -join '\';
        TeamCityPluginsRelativeDir = @("plugins", ".unpacked") -join '\';
        TeamCityLibsRelativeDir = "lib";
        TeamCityJreDir = @($teamCityServerDir, "jre") -join '\';
    }
}