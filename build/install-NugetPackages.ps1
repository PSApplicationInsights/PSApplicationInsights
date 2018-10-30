#cd .\PSAppInsights

if (!(Test-Path nuget.exe))
{
    $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $targetNugetExe = "nuget.exe"
    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
    Set-Alias nuget $targetNugetExe -Scope Global -Verbose
}

#Make sure to update Nuget 
.\nuget.exe update -self
#Now install the packages as specified in ther packages.config file 
.\nuget.exe install ..\packages.config -o ../packages

