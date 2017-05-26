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

function Install-TeamCityBackupInTaskScheduler {
    <#
    .SYNOPSIS
    Creates a task that runs TeamCity backup and adds it to Windows Scheduler. Need to have administrative privileges.

    .PARAMETER OutputBackupDir
    Location of output backup directory.

    .PARAMETER SecondaryBackupDir
    Location of secondary output backup directory.

    .PARAMETER Trigger
    Trigger for scheduled task. See http://technet.microsoft.com/en-us/library/hh849759.aspx for examples.

    .PARAMETER PasswordFile
    Path to the file containing password used for backup. Should contain only one line with the password, and should be stored in a properly secured directory.

    .PARAMETER PrimaryRetentionInDays
    Backups older than $PrimaryRetentionInDays days will be deleted from OutputBackupDir after successfully created the new one.

    .PARAMETER SecondaryRetentionInDays
    Backups older than $SecondaryRetentionInDays days will be deleted from SecondaryBackupDir after successfully created the new one.

    .PARAMETER Credentials
    Credentials for scheduled task.

    .PARAMETER TaskName
    Task name in task scheduler.

    .PARAMETER MailSmtpServer
    SMTP server to use for sending success/failure e-mails.

    .PARAMETER MailFrom
    String to put in e-mail 'from'.

    .PARAMETER MailRecipients
    E-mail recipients.

    .PARAMETER MailUser
    User for SMTP authentication.

    .PARAMETER MailPassword
    Password for SMTP authentication.

    .EXAMPLE
    Install-TeamCityBackupInTaskScheduler -OutputBackupDir "D:\TeamCityBackup" -Trigger (New-JobTrigger -Daily -At "4:00 AM")
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputBackupDir, 

        [Parameter(Mandatory=$false)]
        [string]
        $SecondaryBackupDir, 

        [Parameter(Mandatory=$true)]
        #[Microsoft.PowerShell.ScheduledJob.ScheduledJobTrigger] # this breaks ScriptCop :(
        [object]
        $Trigger,

        [Parameter(Mandatory=$true)]
        [string]
        $PasswordFile,

        [Parameter(Mandatory=$false)]
        [int]
        $PrimaryRetentionInDays,

        [Parameter(Mandatory=$false)]
        [int]
        $SecondaryRetentionInDays,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter(Mandatory=$false)]
        [string]
        $TaskName = 'TeamCity daily backup',

        [Parameter(Mandatory=$false)]
        [string]
        $MailSmtpServer,

        [Parameter(Mandatory=$false)]
        [string]
        $MailFrom,

        [Parameter(Mandatory=$false)]
        [string]
        $MailRecipients,

        [Parameter(Mandatory=$false)]
        [string]
        $MailUser,

        [Parameter(Mandatory=$false)]
        [string]
        $MailPassword
    )
    
    Test-IsAdmin -ThrowErrorIfNot

    try { 
        $outputBackupDirExists = Test-Path -LiteralPath $OutputBackupDir
        if (!$OutputBackupDirExists) {
            Write-Log -Warn "Backup directory '$OutputBackupDir' does not exist. Please ensure it exists and set appropriate permissions."
        }
    } catch {
        Write-Log -Warn "Backup directory '$OutputBackupDir' does not exist (or there is double-hop issue). Please ensure it exists and set appropriate permissions. Exception: $_"
    }
    try { 
        $outputBackupDirExists = Test-Path -LiteralPath $SecondaryBackupDir
        if (!$OutputBackupDirExists) {
            Write-Log -Warn "Backup directory '$SecondaryBackupDir' does not exist. Please ensure it exists and set appropriate permissions."
        }
    } catch {
        Write-Log -Warn "Backup directory '$SecondaryBackupDir' does not exist (or there is double-hop issue). Please ensure it exists and set appropriate permissions. Exception: $_"
    }

    # just ensure the password can be read
    [void](Read-TeamCityPasswordFile -Password $PasswordFile)

    Write-Log -Info "Installing a TeamCity backup task named '$TaskName' in task scheduler for user '$($Credentials.UserName)'" -Emphasize

    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue 
    if ($task) {
        Write-Log -Info "Task '$TaskName' already exists - removing."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    $backupParams  = "-OutputBackupDir '$OutputBackupDir' "
    $backupParams += "-SecondaryBackupDir '$SecondaryBackupDir' "
    $backupParams += "-PasswordFile '$PasswordFile' "
    if ($PrimaryRetentionInDays) {
        $backupParams += "-PrimaryRetentionInDays '$PrimaryRetentionInDays' "
    }
    if ($SecondaryRetentionInDays) {
        $backupParams += "-SecondaryRetentionInDays '$SecondaryRetentionInDays' "
    }
    if ($MailSmtpServer -and $MailRecipients) {
        $backupParams += "-MailSmtpServer '$MailSmtpServer' -MailFrom '$MailFrom' -MailRecipients '$MailRecipients' -MailUser '$MailUser' -MailPassword '$MailPassword'"
    }

    $scheduledTaskActionParams = @{ 
        Execute = 'powershell.exe'
        Argument = "-Command `"& { . .\Run-TeamCityBackup.ps1 $backupParams }`""
        WorkingDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'bat'
    }
    $scheduledTaskAction = New-ScheduledTaskAction @scheduledTaskActionParams
    $settings = New-ScheduledTaskSettingsSet

    $task = New-ScheduledTask -Action $scheduledTaskAction -Trigger $trigger -Settings $settings 
    $taskDefinition =  Register-ScheduledTask -TaskName $TaskName -InputObject $task -User $Credentials.UserName -Password $Credentials.GetNetworkCredential().Password

    if (!$taskDefinition) {
        throw "Failed to register task."
    }
    Write-Log -Info "Scheduled task '$TaskName' created successfully." -Emphasize
}

