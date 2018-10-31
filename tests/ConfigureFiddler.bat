@ECHO OFF

set currentDir=%~dp0
cd "%currentDir%"

set fiddler_custom_script_dir="%userprofile%\Documents\Fiddler2\Scripts\"
set fiddler_result_dir="C:\fiddler\"
for /f "tokens=2*" %%a in ('reg.exe query HKEY_CURRENT_USER\Software\Microsoft\Fiddler2\InstallerSettings /v InstallPath') do set "fiddler_binary_dir=%%~b"

echo "Start Fiddler Script"
echo "Current Dir: %currentDir%"
echo "Update values in the registry"
reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Fiddler2" /v CaptureCONNECT /t REG_SZ /d True /f 
reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Fiddler2" /v CaptureHTTPS /t REG_SZ /d True /f
reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Fiddler2" /v IgnoreServerCertErrors /t REG_SZ /d True /f

reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Fiddler2" /v CaptureCONNECT /t REG_SZ /d True /f 
reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Fiddler2" /v CaptureHTTPS /t REG_SZ /d True /f 
reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Fiddler2" /v IgnoreServerCertErrors /t REG_SZ /d True /f 

echo "Create folder for results: %fiddler_result_dir%"
mkdir "%fiddler_result_dir%"

echo "Create folder for the custom fiddler's script: %fiddler_custom_script_dir%"
mkdir "%fiddler_custom_script_dir%" 

echo "Copy fiddler script to  %fiddler_custom_script_dir%"
copy /Y /V "%currentDir%\Fiddler-CustomRules-InitHttps.js" "%fiddler_custom_script_dir%\CustomRules.js"

echo "Start fiddler"
start "" "%fiddler_binary_dir%\fiddler.exe" -quiet

set cert_path="%currentDir%\FiddlerRoot.cer"
set /a attempt=0

timeout 10 > nul

:get_cert
    set /a attempt+=1
    timeout 1 > nul
    echo "Attempt #%attempt% to download fiddeler's certificate"
    curl.exe -s -k -o "%cert_path%" "http://127.0.0.1:8888/FiddlerRoot.cer"
if not exist "%cert_path%" if %attempt% LSS 300 goto get_cert

if not exist "%cert_path%" (
    echo "FAIL. Certificate "%cert_path%" doesn't exist. Cannot set trusted certificate"
    exit /b -100
)

set /a attempt=0
echo "Try to add certificate to trusted"
echo certutil -addstore -f "Root" %cert_path%
:import_cert
    set /a attempt+=1
    timeout 1 > nul
    echo "Attempt #%attempt% to download fiddler's certificate
    certutil -addstore -f "Root" %cert_path%
if "%errorlevel%" LSS 0 if %attempt% LSS 3 goto import_cert

echo "End..."