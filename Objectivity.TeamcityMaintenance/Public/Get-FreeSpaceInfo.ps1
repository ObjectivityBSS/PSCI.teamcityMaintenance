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

function Get-FreeSpaceInfo {
    <#
    .SYNOPSIS
    Gets information about free space at each logical disk.

    .PARAMETER WarningThresholdInBytes
    If specified, '!!!' will be prepended to the line with disk that has less free space.

    .EXAMPLE
    Get-FreeSpaceInfo -WarningThresholdInBytes (10*1024*1024*1024)
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [long]
        $WarningThresholdInBytes
    )

    $result = "Free space:`n"
    $diskInfo = Get-WmiObject Win32_logicaldisk | Where-Object { $_.Size }

    foreach ($disk in $diskInfo) {
        $freeSpace = Convert-BytesToSize -Size ($disk.FreeSpace)
        if ($WarningThreshold -and $disk.FreeSpace -lt $WarningThresholdInBytes) { 
            $warn = '!!!'
        } else {
            $warn = ''
        }
        $result += ("{0}{1} {2}`n" -f $warn, $disk.DeviceID, $freeSpace)
    }

    return $result
   
}
