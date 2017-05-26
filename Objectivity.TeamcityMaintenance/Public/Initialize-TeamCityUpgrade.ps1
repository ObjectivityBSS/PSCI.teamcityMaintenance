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

function Initialize-TeamCityUpgrade {
    <#
    .SYNOPSIS
    This cmdlet should be run before starting TeamCity upgrade. It ensures certificates are properly restored, and guides the user through the upgrade process.

    .EXAMPLE
    Initialize-TeamCityUpgrade
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param()

    $workingDir = Get-Location | Select-Object -ExpandProperty Path
    $teamcityPaths = Get-TeamCityPaths
    $teamcityBackupPaths = Get-TeamCityBackupPaths -BaseBackupDir $workingDir

    Backup-TeamCityCertificates -TeamcityPaths $teamcityPaths -TeamcityBackupPaths $teamCityBackupPaths

    Write-Log -Info ("Certificates have been copied to '{0}'." -f $teamcityBackupPaths.CertificatesDir)

    #TODO: BACKUP JRE!

    Write-Log -Info @"
Please ensure that you have the following before continuing:
a) current TeamCity backup, 
b) credentials for Teamcity user (will be needed during TeamCity installation)

Then, run the TeamCity installer. Don't run the TeamCity service after the installation, but instead continue this script after the installation finishes.
"@ -Emphasize

    Request-UserInputToContinue

    Restore-TeamCityCertificates -TeamCityPaths $teamCityPaths -TeamCityBackupPaths $teamCityBackupPaths

    Write-Log -Info ("Deleting directory '{0}'" -f $teamcityBackupPaths.CertificatesDir)
    Remove-Item -LiteralPath $teamcityBackupPaths.CertificatesDir -Force -Recurse
    Write-Log -Info "Certificates restored. Please start the TeamCity service and enjoy the new version. Please also create a new TeamCity backup as soon as possible." -Emphasize
    
}