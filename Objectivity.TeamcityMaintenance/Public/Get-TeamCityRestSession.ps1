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

function Get-TeamCityRestSession {
    <#
    .SYNOPSIS
    Gets or creates a TeamCity REST session using current Windows credentials.
    
    .DESCRIPTION 
    Returns WebRequestSession object that can be used in Invoke-WebRequestWrapper calls.
    The session is stored in global variable $teamCityWebSession.

    .PARAMETER Server
    TeamCity Server name.

    .PARAMETER ForceCreatingNewSession
    If true, new session will be always created, regardless whether it already exists.

    .EXAMPLE
    Get-TeamCityRestSession -Server "TeamCityServer"
    #>

    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $Server, 
        
        [Parameter(Mandatory=$false)]
        [switch] 
        $ForceCreatingNewSession
    )

    if (!$global:TeamCityWebSession -or $ForceCreatingNewSession) {
        $uri = "http://$Server/ntlmLogin.html"
        Write-Log -Info "Accessing TeamCity NTLM login page."
        [void](Invoke-WebRequestWrapper -Uri $uri -Method GET -UseDefaultCredentials -SessionVariable webSession)
        if (!$webSession) {
            throw "Failed to create a web session."
        }
        $global:TeamCityWebSession = $webSession
        return $webSession
    } else {
        return $global:TeamCityWebSession
    }
}

