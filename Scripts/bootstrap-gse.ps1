[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [string] $modernFolderRobotsExe="C:\Temp\ModernRobotProvisioning.exe"

)
if (Test-Path -Path $modernFolderRobotsExe) {
    & $modernFolderRobotsExe
}

Remove-Item "C:\Temp" -Force -Recurse