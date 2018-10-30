Get-Module -Name 'PSApplicationInsights' -All | Remove-Module -Force -ErrorAction SilentlyContinue
cd C:\mize\dev\GitHub\PSApplicationInsights\PSApplicationInsights
c:
Import-Module .\src\PSApplicationInsights.psd1
Get-Module


$key = "b437832d-a6b3-4bb4-b237-51308509747d"
$Client = New-AIClient -Key $key -Verbose
Send-AIEvent "Basic Hashed non-PII information"


Invoke-psake .\build\psakefile.ps1