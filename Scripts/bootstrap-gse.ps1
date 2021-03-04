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


# if (Test-Path -Path $modernFolderRobotsExe) {
    
#     & $modernFolderRobotsExe -u $username  -r $robotName -d $domain
# }

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

function Task {
    param (
        [Parameter(Mandatory = $true)]
        [string] $path,

        [Parameter(Mandatory = $true)]
        [string] $args

    )

    $STAction = @()
    # Set up action to run
    $STAction += New-ScheduledTaskAction `
        -Execute 'NET' `
        -Argument 'START "UiRobotSvc"'

    $STAction += New-ScheduledTaskAction `
        -Execute "$path" `
        -Argument "$args"

    # Set up trigger to launch action
    $STTrigger = New-ScheduledTaskTrigger `
        -Once `
        -At ([DateTime]::Now.AddMinutes(1)) `
        -RepetitionInterval (New-TimeSpan -Minutes 2) `
        -RepetitionDuration (New-TimeSpan -Minutes 10)

    # Set up base task settings - NOTE: Win8 is used for Windows 10
    $STSettings = New-ScheduledTaskSettingsSet `
        -Compatibility Win8 `
        -MultipleInstances IgnoreNew `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -Hidden `
        -StartWhenAvailable

    # Name of Scheduled Task
    $STName = "UiPathRobot"

    # Create Scheduled Task
    Register-ScheduledTask `
        -Action $STAction `
        -Trigger $STTrigger `
        -Settings $STSettings `
        -TaskName $STName `
        -Description "Executes Machine Policy Retrieval Cycle." `
        -User "NT AUTHORITY\SYSTEM" `
        -RunLevel Highest

    # Get the Scheduled Task data and make some tweaks
    $TargetTask = Get-ScheduledTask -TaskName $STName

    # Set desired tweaks
    $TargetTask.Author = 'UiPath'
    $TargetTask.Triggers[0].StartBoundary = [DateTime]::Now.ToString("yyyy-MM-dd'T'HH:mm:ss")
    $TargetTask.Triggers[0].EndBoundary = [DateTime]::Now.AddMinutes(3).ToString("yyyy-MM-dd'T'HH:mm:ss")
    $TargetTask.Settings.AllowHardTerminate = $True
    #$TargetTask.Settings.DeleteExpiredTaskAfter = 'PT5S'
    $TargetTask.Settings.ExecutionTimeLimit = 'PT10M'
    $TargetTask.Settings.volatile = $False

    # Save tweaks to the Scheduled Task
    $TargetTask | Set-ScheduledTask

}


Task -Path $modernFolderRobotsExe -args " -u $username  -r $robotName -d $domain"
