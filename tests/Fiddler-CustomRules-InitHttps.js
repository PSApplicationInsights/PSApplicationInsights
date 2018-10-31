import System;
import System.Windows.Forms;
import Fiddler;

/**
 This script must be in the folder C:\Users\<USER>\Documents\Fiddler2\Scripts\CustomRules.js
 */
class Handlers
{
    // The Main() function runs everytime your FiddlerScript compiles
    static function Main() {
        var today: Date = new Date();
        FiddlerObject.StatusText = " CustomRules.js was loaded at: " + today;
        CertMaker.createRootCert();
        //CertMaker.GetRootCertificate().GetPublicKeyString()
    }

     // The OnExecAction function is called by either the QuickExec box in the Fiddler window,
    // or by the ExecAction.exe command line utility.
    static function OnExecAction(sParams: String[]): Boolean {

        FiddlerObject.StatusText = "ExecAction: " + sParams[0];

        var sAction = sParams[0].toLowerCase();
        switch (sAction) {
        case "quit":
            UI.actExit();
            return true;
        }
    }
}