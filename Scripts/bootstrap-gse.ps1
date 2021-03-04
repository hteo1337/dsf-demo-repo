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



function Register-EventScript {
    param (
        [string] $eventToRegister, # Either Startup or Shutdown
        [string] $pathToScript,
        [string] $scriptParameters
    )
    
    $path = "$ENV:systemRoot\System32\GroupPolicy\Machine\Scripts\$eventToRegister"
    if (-not (Test-Path $path)) {
        # path HAS to be available for this to work
        New-Item -path $path -itemType Directory
    }

    # Add script to Group Policy through the Registry
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\$eventToRegister\0\0",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\$eventToRegister\0\0" |
    ForEach-Object { 
        if (-not (Test-Path $_)) {
            New-Item -path $_ -force
        }
    }

    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\$eventToRegister\0",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\$eventToRegister\0" |
    ForEach-Object {
        New-ItemProperty -path "$_" -name DisplayName -propertyType String -value "Local Group Policy" -force
        New-ItemProperty -path "$_" -name FileSysPath -propertyType String -value "$ENV:systemRoot\System32\GroupPolicy\Machine"  -force
        New-ItemProperty -path "$_" -name GPO-ID -propertyType String -value "LocalGPO" -force
        New-ItemProperty -path "$_" -name GPOName -propertyType String -value "Local Group Policy" -force
        New-ItemProperty -path "$_" -name PSScriptOrder -propertyType DWord -value 2  -force
        New-ItemProperty -path "$_" -name SOM-ID -propertyType String -value "Local" -force
    }
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\Scripts\$eventToRegister\0\0",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\$eventToRegister\0\0" |
    ForEach-Object {
        New-ItemProperty -path "$_" -name Script -propertyType String -value $pathToScript -force 
        New-ItemProperty -path "$_" -name Parameters -propertyType String -value $scriptParameters -force
        New-ItemProperty -path "$_" -name IsPowershell -propertyType DWord -value 0 -force
        New-ItemProperty -path "$_" -name ExecTime -propertyType QWord -value 0 -force
    }
}

# get crrentlocation so we can form the full path to the script to register
# $currentLocation = $PSScriptRoot

# register the script twice
# Register-EventScript -eventToRegister "Startup" -pathToScript "$currentLocation\ScriptToRun.ps1" -scriptParameters "OnStartup"
#  Register-EventScript -eventToRegister "Shutdown" -pathToScript "C:\Temp\ModernRobotProvisioning.exe -dp" -scriptParameters "OnShutdown"