[![Build status](https://ci.appveyor.com/api/projects/status/srw27yfledi8oici/branch/master?svg=true)](https://ci.appveyor.com/project/MichelZ/psapplicationinsights/branch/master)

# PSApplicationInsights
Application Insights for PowerShell scripts and Modules

# Samples
The following sample scripts are available to get you started:

## Basic Use
./Sample/Basic Use.ps1

./Sample/Live Metrics.ps1

## Exceptions
Demonstration of the Exeption Logging capabilities of Application Insights 
./Sample/LogExceptions.ps1

## Performance Counters
Start collection perfromance counters and send them to App Insights
./Sample/PerformanceCounters.ps1

## Advanced Tracing
Sample of helper functions and extended tracing
./Sample/advanced tracing.ps1


# Development
- install psake # Build Automation Tool
Install-Module -Name psake

- install pester # PS Unit Test Tool
Install-Module -Name Pester -Force -SkipPublisherCheck

- install CredentialManager
Install-Module -Name CredentialManager 