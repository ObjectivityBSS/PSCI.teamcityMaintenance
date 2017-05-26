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

Import-Module "$PSScriptRoot\..\Objectivity.TeamcityMaintenance.psd1"; 

Get-TeamCityRestorePlan

$backupFile = Read-Host 'Please specify path to the backup file (e.g. D:\TeamCityBackups\TeamCity.7z):'
if (!(Test-Path $backupFile)) {
    throw "Cannot access the backup file at '$backupFile'."
}
$archivePassword = Read-Host 'Please provide password to the backup file: '
if ($archivePassword) {
    $psCredential = ConvertTo-PSCredential -Password $archivePassword
}

$shouldOverwriteExistingDataInput = Read-Host 'Should all existing TeamCity data be overwritten if it exists [y/n]?'
$shouldOverwriteExistingData = $false
if ($shouldOverwriteExistingDataInput -ieq 'y') {
    $shouldOverwriteExistingData = $true
}

$restoreToInternalDatabaseInput = Read-Host 'Should the data be restored to an internal TeamCity database (not suitable for production) [y/n]?'
$restoreToInternalDatabase = $false
if ($restoreToInternalDatabaseInput -ieq 'y') {
    $restoreToInternalDatabase = $true
}

if (!$restoreToInternalDatabase) {
    $success = $false
    do {
        $databasePropertiesFile = Read-Host 'Please specify path to database.properties file, or leave empty if should use connection string saved in backup: '
        if ($databasePropertiesFile -and (!Test-Path $databasePropertiesFile)) {
            Write-Log -Error "Cannot access the file at '$databasePropertiesFile'"
        } else {
            $success = $true
        }
    } while (!$success)
}

Restore-TeamCityData -BackupFile $backupFile -OverwriteExistingData:$shouldOverwriteExistingData -Password $psCredential -RestoreToInternalDatabase:$restoreToInternalDatabase -DatabasePropertiesFile:$databasePropertiesFile
