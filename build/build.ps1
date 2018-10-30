Install-Module Psake, BuildHelpers, CredentialManager -force
Install-Module Pester -Force -SkipPublisherCheck
Import-Module Psake, BuildHelpers
"$($PSScriptRoot)\install-NugetPackages.ps1"
Set-BuildEnvironment
Invoke-psake "$($PSScriptRoot)\psakefile.ps1" -Verbose