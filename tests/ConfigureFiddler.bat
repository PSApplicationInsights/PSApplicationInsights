@ECHO OFF

set currentDir=%~dp0
cd "%currentDir%"

set log="%currentDir%\fiddler.log"
set fiddler_custom_script_dir="%userprofile%\Documents\Fiddler2\Scripts\"
set fiddler_result_dir="C:\fiddler\"
for /f "tokens=2*" %%a in ('reg.exe query HKEY_CURRENT_USER\Software\Microsoft\Fiddler2\InstallerSettings /v InstallPath') do set "fiddler_binary_dir=%%~b"

echo "Start Fiddler Script" > "%log%"
echo "Current Dir: %currentDir%" >> "%log%"
echo "Update values in the registry" >> "%log%"
reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Fiddler2" /v CaptureCONNECT /t REG_SZ /d True /f >> "%log%"
reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Fiddler2" /v CaptureHTTPS /t REG_SZ /d True /f >> "%log%"
reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Fiddler2" /v IgnoreServerCertErrors /t REG_SZ /d True /f >> "%log%"

reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Fiddler2" /v CaptureCONNECT /t REG_SZ /d True /f >> "%log%"
reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Fiddler2" /v CaptureHTTPS /t REG_SZ /d True /f >> "%log%"
reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Fiddler2" /v IgnoreServerCertErrors /t REG_SZ /d True /f >> "%log%"

echo "Create folder for results: %fiddler_result_dir%" >> "%log%"
mkdir "%fiddler_result_dir%" >> "%log%"

echo "Create folder for the custom fiddler's script: %fiddler_custom_script_dir%" >> "%log%"
mkdir "%fiddler_custom_script_dir%" >> "%log%"

echo "Copy fiddler script to  %fiddler_custom_script_dir%" >> "%log%"
copy /Y /V "%currentDir%\CustomRules.js" "%fiddler_custom_script_dir%\CustomRules.js" >> "%log%"

echo "Start fiddler" >> "%log%"
start "" "%fiddler_binary_dir%\fiddler.exe" -quiet

set cert_path="%currentDir%\FiddlerRoot.cer"
set /a attempt=0

timeout 10 > nul

:get_cert
    set /a attempt+=1
    timeout 1 > nul
    echo "Attempt #%attempt% to download fiddeler's certificate" >> "%log%"
    curl.exe -s -k -o "%cert_path%" "http://127.0.0.1:8888/FiddlerRoot.cer" >> "%log%"
if not exist "%cert_path%" if %attempt% LSS 300 goto get_cert

if not exist "%cert_path%" (
    echo "FAIL. Certificate "%cert_path%" doesn't exist. Cannot set trusted certificate"  >> "%log%"
    exit /b -100
)

set /a attempt=0
echo "Try to add certificate to trusted" >> "%log%"
echo certutil -addstore -f "Root" %cert_path% >> "%log%"
:import_cert
    set /a attempt+=1
    timeout 1 > nul
    echo "Attempt #%attempt% to download fiddler's certificate" >> "%log%"
    certutil -addstore -f "Root" %cert_path% >> "%log%"
if "%errorlevel%" LSS 0 if %attempt% LSS 3 goto import_cert

echo "End..." >> "%log%"
exit /b 0