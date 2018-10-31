@{
    # If authoring a script module, the RootModule is the name of your .psm1 file
    #RootModule = 'MyModule.psm1'

    Author = 'Jos Verlinde <josverl@microsoft.com>'

    CompanyName = 'Microsoft'

    ModuleVersion = '0.7'

    # Use the New-Guid command to generate a GUID, and copy/paste into the next line
    GUID = '0e89d29e-d2ad-43b3-9f0f-805cb6e07798'

    Copyright = '2017 Jos Verlinde'

    Description = 'Test functions to capture HTTP/HTTPS information sent to a webservice or similar during testing '

    # Minimum PowerShell version supported by this module (optional, recommended)
    # PowerShellVersion = ''

    # Which PowerShell Editions does this module work with? (Core, Desktop)
    CompatiblePSEditions = @('Desktop')

    # Which PowerShell functions are exported from your module? (eg. Get-CoolObject)
    FunctionsToExport = @('*')

    # Which PowerShell aliases are exported from your module? (eg. gco)
    AliasesToExport = @('')

    # Which PowerShell variables are exported from your module? (eg. Fruits, Vegetables)
    VariablesToExport = @('')

    # PowerShell Gallery: Define your module's metadata
    PrivateData = @{
        PSData = @{
            # What keywords represent your PowerShell module? (eg. cloud, tools, framework, vendor)
            Tags = @('Fiddler', 'Pester','Test')

            # What software license is your code being released under? (see https://opensource.org/licenses)
            LicenseUri = ''

            # What is the URL to your project's website?
            ProjectUri = ''

            # What is the URI to a custom icon file for your project? (optional)
            IconUri = ''

            # What new features, bug fixes, or deprecated features, are part of this release?
            ReleaseNotes = @'
'@
        }
    }


}
<#
Test functions to capture information send to AI during testing 

Ensure-Fiddler          Makes sure Fiddler is started (It must be configured to capture non-browser or All traffic)
Start-FiddlerCapture    Clears any capture in fiddler and starts a fresh capture 
Stop-FiddlerCapture     Stops capturing, but leaves Fiddler Running
Save-FiddlerCapture     Saves all data captured from the curren Process to a JSON format (requires a FiddlerScript function to be added)
Read-FiddlerAICapture   Read and process the Capture , and processess the JSON objects in post and body support testing.
Stop-Fiddler            Stops Fiddler 
#>

function Ensure-Fiddler {
[CmdletBinding()]
[OutputType([void])]    
Param (
    [Switch]$Show
)
   
    if ($Show) { 
        $Action = " "
    } else {
        $Action = "-quiet"
    }
    #Make Sure fiddler is started 
    if (-not (Get-Process -Name 'Fiddler' -ErrorAction SilentlyContinue)) { 
        Start-Process "$(Get-FiddlerBinary -Name 'Fiddler')" -ArgumentList $Action 

        #Wait for Fiddler to start 
        while(-not (Get-Process -Name 'Fiddler' -ErrorAction SilentlyContinue)) {    
            Start-Sleep -Milliseconds 200  
        }

        Start-Job  -Name 'Start Fiddler, stop capture' -ScriptBlock { 
            #Try a few times until we can control it
            for ($i = 0; $i -lt 10; $i++) {
                $R = &"$(Get-FiddlerBinary -Name 'ExecAction')" "Stop"
                "Wait $i"
                Start-Sleep -Milliseconds 200
            } 
        } | Out-Null
    }
}

function Start-FiddlerCapture  {
[CmdletBinding()]
[OutputType([void])]    
param (
    [Switch]$Show    
)   
    Ensure-Fiddler -Show:$Show
    if ($Show) { 
        &"$(Get-FiddlerBinary -Name 'ExecAction')" Show
    } else {
        &"$(Get-FiddlerBinary -Name 'ExecAction')" hide
    }
    &"$(Get-FiddlerBinary -Name 'ExecAction')" clear
    &"$(Get-FiddlerBinary -Name 'ExecAction')" start
 
}
function Stop-FiddlerCapture  {
[CmdletBinding()]
[OutputType([void])]    
param (
    [Switch]$Show    
)   
    Ensure-Fiddler -Show:$Show
    if ($Show) { 
        &"$(Get-FiddlerBinary -Name 'ExecAction')" Show
    } else {
        &"$(Get-FiddlerBinary -Name 'ExecAction')" hide
    }
    &"$(Get-FiddlerBinary -Name 'ExecAction')" stop
}

function Save-FiddlerCapture  {
[CmdletBinding()]
[OutputType([bool])]    
Param (
    $fileName = "$($env:TEMP)LastSession.json",
    $ProcessID = $PID,
    [Switch]$Show
)
    Ensure-Fiddler -Show:$Show

    Write-Verbose "Saving fiddler capture for ProcessID: $($ProcessID) to FileName: $($fileName)"

    if ($Show) { 
        &"$(Get-FiddlerBinary -Name 'ExecAction')" Show
    } else {
        &"$(Get-FiddlerBinary -Name 'ExecAction')" hide
    }
    &"$(Get-FiddlerBinary -Name 'ExecAction')" stop
    #Select Only the sessions sent by this PowerShell process 
    &"$(Get-FiddlerBinary -Name 'ExecAction')" "select @col.Process :$ProcessID"
    &"$(Get-FiddlerBinary -Name 'ExecAction')" "DumpJson $fileName"

    #Wait for File  For up to 10 secs 
    $timeout = new-timespan -Seconds 10
    $timer = [diagnostics.stopwatch]::StartNew()
    while ( ($timer.elapsed -lt $timeout) -and `
            ((Test-Path $fileName)-eq $false  ))
    {
        Start-Sleep -Milliseconds 200   
    }
    #And a little more to avoid problems while loading later
    Start-Sleep -Milliseconds 100 
    Return (Test-Path $fileName)
 }

function Read-FiddlerAICapture {
[CmdletBinding()]
[OutputType([PSObject[]])]
Param (
    $fileName = "$($env:TEMP)LastSession.json",
    [Switch]$QuickPulse
)
    if (!(Test-Path -LiteralPath $fileName)) {
        Write-warning  "Cannot find path '$fileName' because it does not exist."
        return $null
    }
    $Capture = Get-Content $fileName |Convertfrom-json 
    #$Capture.log.entries= $Capture.log.entries | Where-Object { ($_.request.url -like 'https://*.services.visualstudio.com/*') }      
    if ( $Capture -eq $null -or  $Capture -isnot 'System.Management.Automation.PSCustomObject' ) {
        Write-Verbose 'Read-FiddlerAICapture : Empty file' -Verbose
        return $null
    }
    if ($QuickPulse) {
        #Filter for Only QuickPulse 
        #Make sure to get an array 
        $Capture.log.entries = @($Capture.log.entries| Where-Object { ($_.request.url -like 'https://rt.services.visualstudio.com/QuickPulseService.svc/*') })
        return $Capture
    } else {
        #Filter for only AI traffic
    
        $Capture.log.entries = @( $Capture.log.entries | Where-Object { ($_.request.url -like 'https://dc.services.visualstudio.com/v2/track') })
        #Expand the Telemetry data from the post and the response body

        for ($n = 0; $n -lt $Capture.log.Entries.Count; $n++) {
            #--------------------------------------------
            #Expand the Telemetry data from the post body 
            $Post = $Capture.log.Entries[$n].request.postData.text
            
            #1 JSON Object per Line 
            $Telemetry = ($post.Split("`r") ) | ConvertFrom-Json 
            
            $Capture.log.Entries[$n] | Add-Member -Name 'AITelemetry' -MemberType NoteProperty -Value $Telemetry -Force
            #Get the AI response 
            $AIResponse = $Capture.log.Entries[$n].response.content.text | ConvertFrom-Json -ErrorAction SilentlyContinue
            $Capture.log.Entries[$n] | Add-Member -Name 'AIResponse' -MemberType NoteProperty -Value $AIResponse -Force
        }

        $AllTelemetry= @( $Capture.log.Entries| ForEach-Object { Write-Output $_.AITelemetry } )
        $AllResponses= @( $Capture.log.Entries| ForEach-Object { Write-Output $_.AIResponse } )

        $Capture | Add-Member -Name 'AllTelemetry' -MemberType NoteProperty -Value $AllTelemetry
        $Capture | Add-Member -Name 'AllResponses' -MemberType NoteProperty -Value $AllResponses

        #Count the errors $counts = $Capture.AllResponses | %{ $_.errors.Count}
        $ErrCount = Measure-Object -Sum -InputObject ($Capture.AllResponses | ForEach-Object { if ($_.errors -and $_.errors.Count ){ $_.errors.Count} } )          
        $Capture | Add-Member -Name 'ErrorCount' -MemberType NoteProperty -Value $ErrCount.Sum

        #Dynamic don't work so well 
        #$Capture | Add-Member -Name 'AllTelemetry2' -MemberType ScriptProperty -Value {@( $This.log.Entries| foreach { Write-Output $_.AITelemetry } )}
        #$Capture | Add-Member -Name 'AllResponses2' -MemberType ScriptProperty -Value {@( $This.log.Entries| foreach { Write-Output $_.AIResponse  } )}
        
        Return $Capture
    }
}

Function Get-FiddlerCapture {
[CmdletBinding()]
Param (
    $ProcessID = $PID,
    [Switch]$Show  
)

    $Result = $null
    Try { 
        $fileName = (New-TemporaryFile).FullName
        Write-Verbose "FileName: $($fileName)"
        $Result = Save-FiddlerCapture -FileName $fileName -ProcessID $ProcessID -Show:$Show
        $Result = Read-FiddlerAICapture -FileName $fileName
    } Finally {
        if ($Result -eq $null ) {
            Write-Verbose 'Return an Empty structure' -Verbose
            $Result =  ConvertFrom-Json  -InputObject  '{"log":{"pages":  [],"comment":  "","entries":  [],"creator":  {},"version":  "1.2"},"AllTelemetry":  [],"AllResponses":  []}'
        }
    }

    if (($ENV:PRESERVE_FIDDLER_TRACE) -and (-not ($ENV:PRESERVE_FIDDLER_TRACE).ToLowerInvariant -eq 'true'))
    {
        Remove-Item $fileName -ErrorAction SilentlyContinue 
    }

    Return $Result
}

function Stop-Fiddler {
[CmdletBinding()]
[OutputType([void])]    
param ( [Switch]$wait)    
    #Make Sure fiddler is started 
    if ((Get-Process -Name 'Fiddler' -ErrorAction SilentlyContinue)) { 
        $R = &"$(Get-FiddlerBinary -Name 'ExecAction')" "quit"
    }
    #Clean up any remaining jobs 
    Get-Job  -Name 'Start Fiddler, stop capture' -ErrorAction SilentlyContinue | 
        Stop-Job -ErrorAction SilentlyContinue -PassThru | 
        Remove-Job -Force -ErrorAction SilentlyContinue

    if ($wait) {
        #Wait for Fiddler to stop 
        while((Get-Process -Name 'Fiddler' -ErrorAction SilentlyContinue)) {    
            Start-Sleep -Milliseconds 200  
        }
    }
}

function Get-FiddlerBinary {
[CmdletBinding()]
	param(
		[ValidateSet("ExecAction", "Fiddler")]
		[Parameter(Mandatory = $true)]
		[string]$Name
	)

	switch($Name.ToLowerInvariant())
	{
		"execaction" { return "$(Get-FiddlerLocation)ExecAction.exe" }
		"fiddler" {	return "$(Get-FiddlerLocation)Fiddler.exe" }
		default { throw "binary not found" }
	}
}

function Get-FiddlerLocation {
[CmdletBinding()]
param ()

	# Fiddler location
	if (Test-RegistryValue -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Fiddler2\InstallerSettings" -Name "InstallPath")
	{
		return (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\Software\Microsoft\Fiddler2\InstallerSettings -Name InstallPath).InstallPath
	}
	
	return $null
}

function Install-FiddlerScript {
    [CmdletBinding()]
    param ()

    $myDocumentsFolder = [Environment]::GetFolderPath("MyDocuments")
    $fiddlerScriptFolder = "$($myDocumentsFolder)\Fiddler2\Scripts"
    $fiddlerScriptFile = "$($fiddlerScriptFolder)\CustomRules.js"

    if (Test-Path $fiddlerScriptFile)
    {
        $file = Get-Content $fiddlerScriptFile
        $containsWord = $file | %{$_ -match "dumpjson"}
        if ($containsWord -contains $true) {
            Write-Verbose "FiddlerScript already installed. Skipping."
            return
        }
    }

    Write-Verbose "FiddlerScript not installed. Installing."
    
    # Create backup
    if (Test-Path $fiddlerScriptFile)
    {
        Copy-Item $fiddlerScriptFile "$($fiddlerScriptFile)-$(Get-Date -Format 'yyyyMMddhhmmss')"
    }

    if (-not (Test-Path $fiddlerScriptFolder -PathType Container))
    {
        New-Item -ItemType Directory -Force -Path $fiddlerScriptFolder | Out-Null
    }
    
    Copy-Item "$($PSScriptRoot)\Fiddler-CustomRules.js" $fiddlerScriptFile -Force -Confirm:$False
}

function Test-RegistryValue {
    param(
        [Alias("PSPath")]
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Path
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Name
        ,
        [Switch]$PassThru
    ) 

    process {
        if (Test-Path $Path) {
            $Key = Get-Item -LiteralPath $Path
            if ($Key.GetValue($Name, $null) -ne $null) {
                if ($PassThru) {
                    Get-ItemProperty $Path $Name
                } else {
                    $true
                }
            } else {
                $false
            }
        } else {
            $false
        }
    }
}

<#

Fiddlerscript function 

    // The OnExecAction function is called by either the QuickExec box in the Fiddler window,
    // or by the ExecAction.exe command line utility.
    static function OnExecAction(sParams: String[]): Boolean {

-=-=- Start 
	case "dumpjson":
		// JSONDUMP MARKER 		
        var oSessions; 
        var uxString = "All";
		var oExportOptions = FiddlerObject.createDictionary(); 
		var FileName = CONFIG.GetPath("Captures") 
        // get all / selected sessions
        if ( FiddlerApplication.UI.lvSessions.SelectedCount > 0) {
            oSessions = FiddlerApplication.UI.GetSelectedSessions()          
            uxString = "Selected"
        } else { 
            oSessions = FiddlerApplication.UI.GetAllSessions()
            uxString = "All"
        }
        // First Param = full filename
        if ( sParams.length <= 1 || sParams[1] == "") {
            FileName = CONFIG.GetPath("Captures") + "\Sessions-"+uxString+".json"
        } else {
            FileName = sParams[1]
        }
		oExportOptions.Add("Filename", FileName ); 
		oExportOptions.Add("MaxTextBodyLength", 1024); 
		oExportOptions.Add("MaxBinaryBodyLength", 16384); 
		FiddlerApplication.DoExport("HTTPArchive v1.2", oSessions, oExportOptions, null); 
		FiddlerObject.StatusText = "Dumped "+ uxString +" sessions to JSON in " + FileName ;
		return true;			
			
-=-=- end

#>

Install-FiddlerScript -Verbose