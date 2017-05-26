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

function Get-TeamCityPinnedBuildsInfo() {
    <#
    .SYNOPSIS
    Gets a list of all Pinned Build directories. It uses REST API to get them.

    .PARAMETER Server
    TeamCity Server name.

    .EXAMPLE
    $buildDirs = Get-TeamCityPinnedBuildsInfo -Server $Server
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $Server
    )

    $result = New-Object -TypeName System.Collections.ArrayList

    $webSession = Get-TeamCityRestSession -Server $Server
    Write-Log -Info "Getting pinned builds"
    $uri = "http://$Server/app/rest/builds?locator=pinned:true"
    $buildListResponse = Invoke-WebRequestWrapper -Uri $uri -Method GET -WebSession $webSession
    $buildListXml = [xml]$buildListResponse.Content
    $builds = $buildListXml.builds.build 

    Write-Log -Info ("Got {0} pinned builds." -f $builds.Count)

    $teamcityPaths = Get-TeamCityPaths
    foreach ($build in $builds) {
        Write-Log -Info "Getting build at: $($build.href)"
        $uri = "http://${Server}$($build.href)"
        $buildInfoResponse = Invoke-WebRequestWrapper -Uri $uri -Method GET -WebSession $webSession -FailOnErrorResponse:$false
        $buildInfoXml = [xml]$buildInfoResponse.Content
        # path format: dataDir\system\artifacts\projectId\buildName\id (buildName replaced / with _)
        $buildTypeName = $buildInfoXml.build.buildType.name -replace '/', '_' -replace '>', '_' -replace '<', '_'
        $buildDir = @($TeamcityPaths.TeamCityArtifactsRelativeDir, $buildInfoXml.build.buildType.projectId, $buildTypeName, $build.id) -join '\'
        Write-Log -Info "Pinned build directory at: '$buildDir'"
        $buildAbsoluteDir = Join-Path -Path $TeamcityPaths.TeamCityDataDir -ChildPath $buildDir
        if (Test-Path -LiteralPath $buildAbsoluteDir) { 
            $items = Get-ChildItem -LiteralPath $buildAbsoluteDir -Recurse -File
            if ($items) {
                $size = ($items | Measure-Object -Property Length -Sum).Sum
            }
        }
        $finishDate = $buildInfoXml.build.finishDate
        if ($finishDate -and $finishDate.Length -gt 8) {
            $finishDate = $finishDate.Substring(0, 8)
        }
        $buildInfo = @{ 
            buildRelativeDir = $buildDir
            buildAbsoluteDir = $buildAbsoluteDir
            buildUrl = $buildInfoXml.build.webUrl
            buildName = $buildInfoXml.build.buildType.name
            projectName = $buildInfoXml.build.buildType.projectName
            pinner = $buildInfoXml.build.pinInfo.user.username
            finishDate = $finishDate
            artifactSize = $size
        }
            
        [void]($result.Add($buildInfo))
    }

    return $result.ToArray()
}
