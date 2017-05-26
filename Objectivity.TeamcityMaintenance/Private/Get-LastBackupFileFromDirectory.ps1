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

function Get-LastBackupFileFromDirectory  {
    <#
    .SYNOPSIS
    Gets last backup file from given directory (sorted by name).

    .PARAMETER Dir
    Directory to search.

    .EXAMPLE
    Get-LastBackupFileFromDirectory -Dir "d:\backup"
    #>
        
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $Dir
    )

    $file = Get-ChildItem -Path "$Dir\*" -Include '*.zip','*.7z' | Sort-Object name -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (!$file) {
        throw ("Cannot find any files at {0}. Please ensure the backup file has not been corrupted." -f $Dir)
    }
    return $file
}
