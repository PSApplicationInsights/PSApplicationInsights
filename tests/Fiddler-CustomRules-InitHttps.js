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
}