function Test-ManifestBool ($path)
{
    $null = Get-ChildItem $path | Test-ModuleManifest -ErrorAction SilentlyContinue $?
}