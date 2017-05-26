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

function Restore-TeamCityData {
    <#
    .SYNOPSIS
    Restores TeamCity data from a backup file created by Backup-TeamCityData cmdlet.

    .PARAMETER BackupFile
    Path to the backup file.

    .PARAMETER DatabasePropertiesFile
    Path to database.properties file. Can be empty if connection stored in backup should be used. See Get-TeamCityRestorePlan for details.

    .PARAMETER RestoreToInternalDatabase
    If true, restore will be made to the internal database (hsqldb). See Get-TeamCityRestorePlan for details.

    .PARAMETER OverwriteExistingData
    If true, all existing TeamCity data will be overwritten.

    .PARAMETER Password
    PSCredential object that stores the password used to decrypt the archive.

    .EXAMPLE
    Restore-TeamCityData -BackupFile $BackupFile -OverwriteExistingData:$shouldOverwriteExistingData -Password $Password -RestoreToInternalDatabase:$RestoreToInternalDatabase -DatabasePropertiesFile:$DatabasePropertiesFile
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $BackupFile,

        [Parameter(Mandatory=$false)]
        [string]
        $DatabasePropertiesFile,

        [Parameter(Mandatory=$false)]
        [switch]
        $RestoreToInternalDatabase,

        [Parameter(Mandatory=$false)]
        [switch]
        $OverwriteExistingData,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]
        $Password
    ) 

    $teamCityPaths = Test-TeamCityRestorePrerequisites -BackupFile $BackupFile -DatabasePropertiesFile $DatabasePropertiesFile -RestoreToInternalDatabase:$RestoreToInternalDatabase -OverwriteExistingData:$OverwriteExistingData
    
    $outputBackupTempDir = New-TempDirectory
    $teamCityBackupPaths = Get-TeamCityBackupPaths -BaseBackupDir $outputBackupTempDir

    if ($OverwriteExistingData) {
        Write-Log -Warn "Clearing TeamCity data directory ('$($teamCityPaths.TeamCityDataDir)')."
        Remove-Item -LiteralPath (Join-Path -Path $teamCityPaths.TeamCityDataDir -ChildPath "*") -Recurse -Force
    }
    Write-Log -Info "Starting TeamCity restore." -Emphasize

    Write-Log -Info "Expanding backup file '$BackupFile' to '$outputBackupTempDir'" -Emphasize
    Expand-With7Zip -ArchiveFile $BackupFile -OutputDirectory $outputBackupTempDir -Password $Password

    Test-TeamCityBuildVersion -TeamCityPaths $teamCityPaths -TeamCityBackupPaths $teamCityBackupPaths
    Restore-TeamCityEnvironmentVariables -TeamCityBackupPaths $teamCityBackupPaths
    Restore-TeamCityZippedPartialBackup -TeamCityPaths $teamCityPaths -BackupDir $teamCityBackupPaths.LibsDir
    Restore-TeamCityRestBackup -TeamCityPaths $teamCityPaths -TeamCityBackupPaths $teamCityBackupPaths -DatabasePropertiesFile $DatabasePropertiesFile -RestoreToInternalDatabase:$RestoreToInternalDatabase

    Restore-TeamCityZippedPartialBackup -TeamCityPaths $teamCityPaths -BackupDir $teamCityBackupPaths.PluginsDir
    Restore-TeamCityZippedPartialBackup -TeamCityPaths $teamCityPaths -BackupDir $teamCityBackupPaths.ArtifactsDir
    Restore-TeamCityCertificates -TeamCityPaths $teamCityPaths -TeamCityBackupPaths $teamCityBackupPaths

   [void](Remove-TempDirectory)
    Write-Log -Info "TeamCity restore complete." -Emphasize
}