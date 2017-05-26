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

Task Build -Depends Init, LicenseChecks {
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

Task LicenseChecks {
    "Running license checks"
    . "$PSScriptRoot\sanity_checks.ps1"
}