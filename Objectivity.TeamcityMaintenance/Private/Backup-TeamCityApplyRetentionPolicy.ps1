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

function Backup-TeamCityApplyRetentionPolicy {
    <#
    .SYNOPSIS
    Applies retention policy to the TeamCity backup directory, i.e. deletes backup older than $RetentionInDays.

    .PARAMETER OutputBackupDir
    Output backup directory to clean.

    .PARAMETER RetentionInDays
    Backups created before this number of days will be deleted.

    .EXAMPLE
    Backup-TeamCityApplyRetentionPolicy -OutputBackupDir $OutputBackupDir -RetentionInDays $RetentionInDays
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $OutputBackupDir, 
        
        [Parameter(Mandatory=$true)]
        [int] 
        $RetentionInDays
    )

    $cutOffDate = (Get-Date).Date.AddDays(-$RetentionInDays + 1)
    $allBackups = Get-ChildItem -Path "$OutputBackupDir\*" -Include '*.zip','*.7z'
    Write-Log -Info ("Retention: found {0} backup files." -f (($allBackups | Measure).Count))
    $backupsToDelete = $allBackups | Where-Object { $_.CreationTime -lt $cutOffDate } | Select-Object -ExpandProperty FullName
    if (!$backupsToDelete) {
        Write-Log -Info "Retention: no backups older than $RetentionInDays days."
        return
    }
    Write-Log -Info "Retention: deleting old backups older than $RetentionInDays days: $backupsToDelete"
    $backupsToDelete | Remove-Item -Force
}