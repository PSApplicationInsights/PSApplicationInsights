[![Build status](https://ci.appveyor.com/api/projects/status/srw27yfledi8oici/branch/master?svg=true)](https://ci.appveyor.com/project/MichelZ/psapplicationinsights/branch/master)

# PSApplicationInsights
Application Insights for PowerShell scripts and Modules

# Compatibility
Only tested on PowerShell 5

# Usage Samples
The following sample scripts are available to get you started:

## Basic Use
[Basic Use](https://github.com/PSApplicationInsights/PSApplicationInsights/blob/master/samples/Basic%20Use.ps1)

[Live Metrics](https://github.com/PSApplicationInsights/PSApplicationInsights/blob/master/samples/Live%20Metrics.ps1)

## Exceptions
Demonstration of the Exception Logging capabilities of Application Insights 

[LogExceptions](https://github.com/PSApplicationInsights/PSApplicationInsights/blob/master/samples/LogExceptions.ps1)

## Performance Counters
Start collection perfromance counters and send them to App Insights

[Performance Counters](https://github.com/PSApplicationInsights/PSApplicationInsights/blob/master/samples/PerformanceCounters.ps1)

## Advanced Tracing
Sample of helper functions and extended tracing

[Advanced Tracing](https://github.com/PSApplicationInsights/PSApplicationInsights/blob/master/samples/advanced%20tracing.ps1)

# Development
- install [psake](https://github.com/psake/psake) (Build Automation Tool)

`Install-Module -Name psake`

- install [pester](https://github.com/pester/Pester) (PS Unit Test Tool)

`Install-Module -Name Pester -Force -SkipPublisherCheck`

- install [CredentialManager](https://github.com/davotronic5000/PowerShell_Credential_Manager)

`Install-Module -Name CredentialManager`

# Unit Testing
As seen above, Unit Tests are executed using Pester.
You also need [Fiddler](https://www.telerik.com/fiddler) installed on your system, this can be done using [chocolatey](https://chocolatey.org/):
`choco install fiddler`

A fiddler script is added automatically. A backup of your current script is created, as it gets overwritten from <MYDOCUMENTS>\Fiddler2\Scripts
The script adds a new Fiddler QuickExec command "dumpjson" to be able to retrieve the captured data in JSON format for PowerShell consumption.