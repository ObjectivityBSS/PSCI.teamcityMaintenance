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

Function Get-TeamCityRestorePlan {
    <#
    .SYNOPSIS
    Outputs steps which need to be followed in order to restore TeamCity from backup. Only for human reading.

    .EXAMPLE
    Get-TeamCityRestorePlan
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param()

    $msg = @"
    To restore TeamCity on a clean server, please follow steps below (see also http://confluence.jetbrains.com/display/TCD8/Restoring+TeamCity+Data+from+Backup):
    1. Ensure you have a valid backup archive.
    <TODO: what if there's no java?>
    2. Download proper version of TeamCity from http://www.jetbrains.com/teamcity/download/. To check build version look into the backup archive (file BUILD.* at root of archive).
    3. Run TeamCity installation with following options:
       a) Destination folder: D:\TeamCity (or C:\TeamCity).
       b) Select components to install: uncheck whole 'Build Agent' tree (install server only).
       c) TeamCity data directory: D:\TeamCityData (or C:\TeamCityData) - must be on the same drive as 'Destination folder'.
       d) TeamCity server port: any (default 80).
       e) Run TeamCity Server under a user account.
       f) Uncheck 'Start TeamCity Server service'.
    4. Open Control Panel / System / Advanced system settings / Environment variables and ensure there is variable TEAMCITY_DATA_PATH in system variables with correct value. 
       Click OK - this is required to refresh environment variables
    5. Ensure the directory pointed by TEAMCITY_DATA_PATH exists and is empty.
    6. You have three options how to restore database:
       a) If you want to use the same database connection as in original backup, prepare the database (create empty database and set user permissions) and run:
          Restore-TeamCityData -BackupFile <pathToYourBackupFile>
       b) If you want to restore to TeamCity internal database (hsqldb - for quick and dirty non-production solution), run:
          Restore-TeamCityData -BackupFile <pathToYourBackupFile> -RestoreToInternalDatabase
       c) If you want to use a new external database connection, prepare the database (for details see http://confluence.jetbrains.com/display/TCD8/Setting+up+an+External+Database),
          create a new database.properties file (you can look at existing <your_backup.7z>\DatabaseProperties\*.dist files for reference) and run:
          Restore-TeamCityData -BackupFile <pathToYourBackupFile> -DatabasePropertiesFile <pathToUnpackedDatabasePropertiesFile>
    
       Note if you're running Restore-TeamCityServer.bat, Restore-TeamCityData cmdlet will be run automatically with specific options basing on your input.
---------------------------------------------------
SQL script to prepare database on MS SQL Server:
CREATE DATABASE TeamCity
GO
ALTER DATABASE [TeamCity] SET RECOVERY SIMPLE WITH NO_WAIT
GO

CREATE LOGIN [TeamCity] WITH PASSWORD=N'<PASSWORD>', DEFAULT_DATABASE=[TeamCity], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [TeamCity]
                                                            
GO
CREATE USER [TeamCity] FOR LOGIN [TeamCity]
GO
USE [TeamCity]
GO
EXEC sp_addrolemember N'db_owner', N'TeamCity'
GO
---------------------------------------------------

"@
    Write-Output $msg
}