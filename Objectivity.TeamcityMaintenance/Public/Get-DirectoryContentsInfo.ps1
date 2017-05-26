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

function Get-DirectoryContentsInfo {
    <#
    .SYNOPSIS
    Gets contents of given directory as a newline-delimited string.

    .PARAMETER Path
    Path to the directory.

    .PARAMETER Include
    Include wildcards.
    
    .EXAMPLE
    Get-DirectoryContentsInfo -Path $OutputBackupDir -Include '*.zip','*.7z'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$false)]
        [string[]]
        $Include
    )

    $result = "Contents of '${Path}':`n"
    if (!(Test-Path -LiteralPath $Path)) {
        $result = '<directory does not exist>'
    } else { 
        $result += (Get-ChildItem -Path "$Path\*" -Include $Include | Select-Object -ExpandProperty Name | Sort-Object) -join "`n"
    }
    return ($result + "`n")
}
