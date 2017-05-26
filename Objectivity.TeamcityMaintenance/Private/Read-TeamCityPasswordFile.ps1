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

function Read-TeamCityPasswordFile {
    <#
    .SYNOPSIS
    Reads a password from specified file and wraps it in PSCredential object.

    .PARAMETER PasswordFile
    Path to the password file.

    .EXAMPLE
    Read-TeamCityPasswordFile -PasswordFile $PasswordFile
    #>

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $PasswordFile
    )

    if (!$PasswordFile) {
        return $null
    }
    if (!(Test-Path -LiteralPath $PasswordFile)) {
        throw ("Cannot access password file at '{0}'. Please ensure it exists and the current user '{1}' has appropriate permissions." -f $PasswordFile, (Get-CurrentUser))
    }
    $pass = Get-Content -Path $PasswordFile -ReadCount 1
    $match = '[\\\| "''<>&^]'
    if ($pass -match $match) {
        throw "There are some disallowed characters in password file ($PasswordFile). Invalid character regexp: $match"
    }
    return (ConvertTo-PSCredential -Password $pass)
}