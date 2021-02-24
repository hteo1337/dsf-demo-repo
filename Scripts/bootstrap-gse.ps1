[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [string] $modernFolderRobotsExe="C:\Temp\robotProvisioner.exe",
    [Parameter(Mandatory = $false)]
    [string] $username,
    [Parameter(Mandatory = $false)]
    [string] $domain="DSF",
    [Parameter(Mandatory = $false)]
    [string] $robotName

)
if (Test-Path -Path $modernFolderRobotsExe) {
    & $modernFolderRobotsExe -u $username -d $domain -r $robotName
}

# Remove-Item "C:\Temp" -Force -Recurse