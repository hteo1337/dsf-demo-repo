[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [string] $modernFolderRobotsExe="C:\Temp\ModernRobotProvisioning.exe",
    [Parameter(Mandatory = $false)]
    [string] $username,
    [Parameter(Mandatory = $false)]
    [string] $domain,
    [Parameter(Mandatory = $false)]
    [string] $robotName

)

Add-MpPreference -ExclusionPath "C:\Temp"


if (Test-Path -Path $modernFolderRobotsExe) {
    
    & $modernFolderRobotsExe -u $username  -r $robotName
}

# Remove-Item "C:\Temp" -Force -Recurse