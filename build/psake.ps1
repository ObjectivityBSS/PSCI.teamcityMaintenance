# Properties passed from command line
Properties {   
}

# Common variables
$ProjectRoot = $ENV:BHModulePath
if (-not $ProjectRoot) {
    $ProjectRoot = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath 'Objectivity.TeamcityMaintenance'
}

$Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
$lines = '----------------------------------------------------------------------'
$buildToolsPath = $PSScriptRoot

# Tasks

Task Default -Depends Build

Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Build -Depends Init, LicenseChecks, StaticCodeAnalysis {
    $lines
    
    # Import-Module to check everything's ok
    Import-Module -Name $ENV:BHModulePath -Force

    if ($ENV:BHBuildSystem -eq 'Teamcity' -or $ENV:BHBuildSystem -eq 'AppVeyor') {
      "Updating module psd1 - FunctionsToExport"
      Set-ModuleFunctions
      
      if ($ENV:PackageVersion) { 
        "Updating module psd1 version to $($ENV:PackageVersion)"
        Update-Metadata -Path $env:BHPSModuleManifest -Value $ENV:PackageVersion
      } 
      else {
        "Not updating module psd1 version - no env:PackageVersion set"
      }
    }
}

Task StaticCodeAnalysis {
    $Results = Invoke-ScriptAnalyzer -Path $ProjectRoot -Recurse -Settings "$PSScriptRoot\PSCIScriptingStyle.psd1" -Verbose
    if ($Results) {
        $ResultString = $Results | Out-String
        Write-Warning $ResultString  
        if ($ENV:BHBuildSystem -eq 'AppVeyor') {
            Add-AppveyorMessage -Message "PSScriptAnalyzer output contained one or more result(s) with 'Error' severity.`
            Check the 'Tests' tab of this build for more details." -Category Error
            Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Failed -ErrorMessage $ResultString
        }        
        throw "Build failed"
    } else {
      if ($ENV:BHBuildSystem -eq 'AppVeyor') {
            Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Passed
      }
    }
}

Task LicenseChecks {
    "Running license checks"
    . "$PSScriptRoot\sanity_checks.ps1"
}