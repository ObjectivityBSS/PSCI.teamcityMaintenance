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

function Backup-TeamCityEnvironmentVariables {
    <#
    .SYNOPSIS
    Creates a backup of TeamCity environment variables (all variables named TEAMCITY* apart from TEAMCITY_DATA_PATH).
    Backup is stored in a json format in a single file.

    .PARAMETER TeamcityBackupPaths
    Object containing information about backup paths - generated by Get-TeamcityBackupPaths.

    .EXAMPLE
    Backup-TeamCityEnvironmentVariables -TeamcityBackupPaths $TeamcityBackupPaths
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(      
        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $TeamcityBackupPaths
    )

    $outputBackupDir = $TeamcityBackupPaths.EnvDir
    [void](New-Item -Path $outputBackupDir -ItemType Directory -Force)
    $outputFile = Join-Path -Path $outputBackupDir -ChildPath "envVars.txt"
    $tcEnvVars = @(Get-ChildItem -Path Env: | Where-Object { $_.Name.StartsWith("TEAMCITY") -and $_.Name -ne "TEAMCITY_DATA_PATH" } | Select-Object -Property Key,Value)
    if (!$tcEnvVars) {
        Write-Log -Warn "No TEAMCITY environment variables apart from TEAMCITY_DATA_PATH - note there should be at least TEAMCITY_SERVER_MEM_OPTS."
        return
    }
    $json = $tcEnvVars | ConvertTo-Json
    Write-Log -Info "Creating backup of $($tcEnvVars.Count) TeamCity environment variables to: '$outputFile'"  -Emphasize
    [void](New-Item -Path $outputFile -ItemType file -Force -Value $json)
}