Import-Module "$($PSModuleRoot)\FiddlerTests.psm1"

<#
Add fiddlerscript to save the SAZ and TXT forms
    FiddlerScript : OnExecAction 

    case "saveselected":
        FiddlerObject.UI.actSaveSessionsToZip(CONFIG.GetPath("Captures") + "selected.saz");
        FiddlerObject.UI.actSaveSessions(CONFIG.GetPath("Captures") + "selected.txt",0);
        FiddlerObject.StatusText = "Saved Selected sessions to " + CONFIG.GetPath("Captures") + "selected.saz";
        return true; 



#>
if ($false) {
Start-Process (Get-FiddlerBinary -Name "Fiddler")

#&"C:\Program Files (x86)\Fiddler2\ExecAction.exe" hide
&(Get-FiddlerBinary -Name "ExecAction") Show

&(Get-FiddlerBinary -Name "ExecAction") clear
&(Get-FiddlerBinary -Name "ExecAction") start

#init a client and send basic PII information for correlation
#this incudes the username and the machine name
$Client = New-AIClient -Key $key -AllowPII 
Send-AIEvent "Allow PII" -Flush


&(Get-FiddlerBinary -Name "ExecAction") stop
#Select the sessions
&(Get-FiddlerBinary -Name "ExecAction") "@dc.services.visualstudio.com"

&(Get-FiddlerBinary -Name "ExecAction") SaveSelected 


ii "C:\Users\josverl\OneDrive - Microsoft\Documents\Fiddler2\Captures"
}
$capturedtext = Get-Content "C:\Users\josverl\OneDrive - Microsoft\Documents\Fiddler2\Captures\selected.txt" #-raw 


$newCall = $True

$capturedtext | %{

        if ($newCall){
            $Call = New-Object PSObject  -Property @{Sent = '';Recieved = '';SentBody = '';RecievedBody = ''} 
            $newCall = $False
            $InSend = $True; $InBody = $False
        }
        if ($_ -like  '-----------------------------------------*') {
                Write-Verbose -Verbose "> "
                Write-Output $Call
                $newCall = $True ;
                #continue;
        }
        if ($_ -eq  '' -and $call.Recieved -ne '') {
            $InBody = $true
        }
        if ($_ -like  'HTTP/*') {
            $InSend = $False
            $InBody = $False
        }

        if ($InSend) {
            $Call.Sent = $Call.Sent + $_
            if ($inBody) {
                $Call.SentBody = $Call.SentBody + $_
            }
        } Else {
            $Call.Recieved = $Call.Recieved + $_
            if ($inBody) {
                $Call.RecievedBody = $Call.RecievedBody + $_
            }

        }        
        
} | Format-List

#Now split on the seperator string 
#Fail
$Sessions = $capturedtext.Split( '------------------------------------------------------------------')
$Sessions.Count