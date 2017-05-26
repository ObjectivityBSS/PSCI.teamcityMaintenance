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

function Backup-TeamCityData {
    <#
    .SYNOPSIS
    Creates a full TeamCity backup on localhost using REST API, manual file copying and reading environment variables.

    .PARAMETER OutputBackupDir
    Location of output backup directory.

    .PARAMETER SecondaryBackupDir
    Location of secondary output backup directory.

    .PARAMETER PasswordFile
    Path to the file containing password used for backup. Should contain only one line with the password, and should be stored in a properly secured directory.

    .PARAMETER PrimaryRetentionInDays
    Backups older than $PrimaryRetentionInDays days will be deleted from OutputBackupDir after successfully created the new one.

    .PARAMETER SecondaryRetentionInDays
    Backups older than $SecondaryRetentionInDays days will be deleted from SecondaryBackupDir after successfully created the new one.

    .LINK
    New-TeamCityRestApiBackup

    .EXAMPLE
    Backup-TeamCityData -OutputBackupDir $OutputBackupDir -PasswordFile $PasswordFile -RetentionInDays $RetentionInDays
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputBackupDir,
        
        [Parameter(Mandatory=$false)]
        [string]
        $SecondaryBackupDir, 

        [Parameter(Mandatory=$false)]
        [string]
        $PasswordFile,

        [Parameter(Mandatory=$false)]
        [int]
        $PrimaryRetentionInDays,

        [Parameter(Mandatory=$false)]
        [int]
        $SecondaryRetentionInDays
    )

    Write-Log -Info "Starting TeamCity backup, output dir: '$OutputBackupDir', secondary output dir: '$SecondaryBackupDir', primary retention: $PrimaryRetentionInDays, secondary retention: $SecondaryRetentionInDays"
    $server = "localhost"
    $teamcityPaths = Get-TeamCityPaths
    $password = Read-TeamCityPasswordFile -PasswordFile $PasswordFile
    
    if (!(Test-Path -LiteralPath $OutputBackupDir)) {
        throw "Backup directory '$OutputBackupDir' does not exist. Please create it and set appropriate permissions."
    }
    
    $outputBackupTempDir = New-TempDirectory -BasePath $OutputBackupDir
    $teamCityBackupPaths = Get-TeamCityBackupPaths -BaseBackupDir $outputBackupTempDir

    Backup-TeamCityBuildVersion -TeamcityPaths $teamcityPaths -TeamcityBackupPaths $teamCityBackupPaths
    Backup-PSCI -TeamcityBackupPaths $teamCityBackupPaths
    Backup-TeamCityAdditionalFiles -TeamcityPaths $teamcityPaths -TeamcityBackupPaths $teamCityBackupPaths
    Backup-TeamCityEnvironmentVariables -TeamcityBackupPaths $teamCityBackupPaths
    Backup-TeamCityCertificates -TeamcityPaths $teamcityPaths -TeamcityBackupPaths $teamCityBackupPaths
    Backup-TeamCityWithRestApi -Server $server -TeamcityPaths $teamcityPaths -TeamcityBackupPaths $teamCityBackupPaths
    Backup-TeamCityArtifacts -Server $server -TeamcityPaths $teamcityPaths -TeamcityBackupPaths $teamCityBackupPaths

    $outputFile = New-TeamCityFinalBackupFile -TeamcityPaths $teamcityPaths -BackupTempDir $outputBackupTempDir -OutputBackupDir $OutputBackupDir -Password $password

    if ($PrimaryRetentionInDays) {
        Backup-TeamCityApplyRetentionPolicy -OutputBackupDir $OutputBackupDir -RetentionInDays $PrimaryRetentionInDays
    }

    if ($SecondaryBackupDir) {
        Write-Log -Info "Copying from '$outputFile' to '$SecondaryBackupDir'"
        Copy-Item -Path $outputFile -Destination $SecondaryBackupDir

        if ($SecondaryRetentionInDays) {
           Backup-TeamCityApplyRetentionPolicy -OutputBackupDir $SecondaryBackupDir -RetentionInDays $SecondaryRetentionInDays
        }
    }

    [void](Remove-TempDirectory -BasePath $OutputBackupDir)
    return $outputFile
}
