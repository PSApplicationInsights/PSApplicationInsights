Install-Module Psake, BuildHelpers, CredentialManager -force
Install-Module Pester -Force -SkipPublisherCheck
Import-Module Psake, BuildHelpers
Set-BuildEnvironment
Invoke-psake .\psakefile.ps1 -Verbose