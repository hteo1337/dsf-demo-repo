[CmdletBinding()]
Param (
  [Parameter()]
  [AllowEmptyString()]
  [string] $robotArtifact = "http://download.uipath.com/UiPathStudioSetup.exe",
  [Parameter()]
  [AllowEmptyString()]
  [string]$artifactFileName = "UiPathStudioSetup.exe"
)
#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
#Script Version
$sScriptVersion = "1.0"
#Debug mode; $true - enabled ; $false - disabled
$sDebug = $true
#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "Install-UiPathRobot.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

function Main {

    #Log log log
    Log-Write -LogPath $sLogFile -LineValue "Install-UiRobot starts"

    #Define TLS for Invoke-WebRequest
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #Setup temp dir in %appdata%\Local\Temp
    $script:tempDirectory = (Join-Path $ENV:TEMP "UiPath-$(Get-Date -f "yyyyMMddhhmmssfff")")
    New-Item -ItemType Directory -Path $script:tempDirectory | Out-Null

    #Download UiPlatform
    $artifactPath = Join-Path $script:tempDirectory $artifactFileName

    $maxAttempts = 5 #set the maximum number of attempts in case the download will never succeed.

    $attemptCount = 0

    Do {

      $attemptCount++
      Download-File -url $robotArtifact -outputFile $artifactPath

    } while (((Test-Path $artifactPath) -eq $false) -and ($attemptCount -le $maxAttempts))


      #Log log log
      Log-Write -LogPath $sLogFile -LineValue "Installing UiPath Robot"

      Try {
        Start-Process $artifactPath /S -NoNewWindow -Wait -PassThru
      }
      Catch {
        Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
        Break
      }
      #End of the Robot installation

      #Remove temp directory
      Log-Write -LogPath $sLogFile -LineValue "Removing temp directory $($script:tempDirectory)"
      Remove-Item $script:tempDirectory -Recurse -Force | Out-Null
}


<#
  .DESCRIPTION
  Downloads a file from a URL

  .PARAMETER url
  The URL to download from

  .PARAMETER outputFile
  The local path where the file will be downloaded
#>
function Download-File {

  param (
    [Parameter(Mandatory = $true)]
    [string]$url,

    [Parameter(Mandatory = $true)]
    [string] $outputFile
  )

  Write-Verbose "Downloading file from $url to local path $outputFile"

  Try {

    $webClient = New-Object System.Net.WebClient

  }

  Catch {

    Log-Error -LogPath $sLogFile -ErrorDesc "The following error occurred: $_" -ExitGracefully $True

  }

  Try {

    $webClient.DownloadFile($url, $outputFile)

  }

  Catch {

    Log-Error -LogPath $sLogFile -ErrorDesc "The following error occurred: $_" -ExitGracefully $True

  }
}

<#
  .SYNOPSIS
    Creates log file

  .DESCRIPTION
    Creates log file with path and name that is passed. Checks if log file exists, and if it does deletes it and creates a new one.
    Once created, writes initial logging data

  .PARAMETER LogPath
    Mandatory. Path of where log is to be created. Example: C:\Windows\Temp

  .PARAMETER LogName
    Mandatory. Name of log file to be created. Example: Test_Script.log

  .PARAMETER ScriptVersion
    Mandatory. Version of the running script which will be written in the log. Example: 1.5

  .INPUTS
    Parameters above

  .OUTPUTS
    Log file created
 #>
function Log-Start {

  [CmdletBinding()]

  param (
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [Parameter(Mandatory = $true)]
    [string]$LogName,

    [Parameter(Mandatory = $true)]
    [string]$ScriptVersion
  )

  Process {
    $sFullPath = $LogPath + "\" + $LogName

    #Check if file exists and delete if it does
    If ((Test-Path -Path $sFullPath)) {
      Remove-Item -Path $sFullPath -Force
    }

    #Create file and start logging
    New-Item -Path $LogPath -Value $LogName -ItemType File

    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value "Started processing at [$([DateTime]::Now)]."
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "Running script version [$ScriptVersion]."
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "Running with debug mode [$sDebug]."
    Add-Content -Path $sFullPath -Value ""
    Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value ""

    #Write to screen for debug mode
    Write-Debug "***************************************************************************************************"
    Write-Debug "Started processing at [$([DateTime]::Now)]."
    Write-Debug "***************************************************************************************************"
    Write-Debug ""
    Write-Debug "Running script version [$ScriptVersion]."
    Write-Debug ""
    Write-Debug "Running with debug mode [$sDebug]."
    Write-Debug ""
    Write-Debug "***************************************************************************************************"
    Write-Debug ""
  }

}


<#
  .SYNOPSIS
    Writes to a log file

  .DESCRIPTION
    Appends a new line to the end of the specified log file

  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log

  .PARAMETER LineValue
    Mandatory. The string that you want to write to the log

  .INPUTS
    Parameters above

  .OUTPUTS
    None
#>
function Log-Write {

  [CmdletBinding()]

  param (
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [Parameter(Mandatory = $true)]
    [string]$LineValue
  )

  Process {
    Add-Content -Path $LogPath -Value $LineValue

    #Write to screen for debug mode
    Write-Debug $LineValue
  }
}

<#
  .SYNOPSIS
    Writes an error to a log file

  .DESCRIPTION
    Writes the passed error to a new line at the end of the specified log file

  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write to. Example: C:\Windows\Temp\Test_Script.log

  .PARAMETER ErrorDesc
    Mandatory. The description of the error you want to pass (use $_.Exception)

  .PARAMETER ExitGracefully
    Mandatory. Boolean. If set to True, runs Log-Finish and then exits script

  .INPUTS
    Parameters above

  .OUTPUTS
    None
#>
function Log-Error {

  [CmdletBinding()]

  param (
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [Parameter(Mandatory = $true)]
    [string]$ErrorDesc,

    [Parameter(Mandatory = $true)]
    [boolean]$ExitGracefully
  )

  Process {
    Add-Content -Path $LogPath -Value "Error: An error has occurred [$ErrorDesc]."

    #Write to screen for debug mode
    Write-Debug "Error: An error has occurred [$ErrorDesc]."

    #If $ExitGracefully = True then run Log-Finish and exit script
    If ($ExitGracefully -eq $True) {
      Log-Finish -LogPath $LogPath
      Break
    }
  }
}

<#
  .SYNOPSIS
    Write closing logging data & exit

  .DESCRIPTION
    Writes finishing logging data to specified log and then exits the calling script

  .PARAMETER LogPath
    Mandatory. Full path of the log file you want to write finishing data to. Example: C:\Windows\Temp\Script.log

  .PARAMETER NoExit
    Optional. If this is set to True, then the function will not exit the calling script, so that further execution can occur

  .INPUTS
    Parameters above

  .OUTPUTS
    None
#>
function Log-Finish {

  [CmdletBinding()]

  param (
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [Parameter(Mandatory = $false)]
    [string]$NoExit
  )

  Process {
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value "Finished processing at [$([DateTime]::Now)]."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value ""

    #Write to screen for debug mode
    Write-Debug ""
    Write-Debug "***************************************************************************************************"
    Write-Debug "Finished processing at [$([DateTime]::Now)]."
    Write-Debug "***************************************************************************************************"
    Write-Debug ""

    #Exit calling script if NoExit has not been specified or is set to False
    If (!($NoExit) -or ($NoExit -eq $False)) {
      Exit
    }
  }
}

function robotTask {
  param (
    [Parameter(Mandatory = $true)]
    [string] $robotPath,

    [Parameter(Mandatory = $true)]
    [string] $orcURL,

    [Parameter(Mandatory = $true)]
    [string] $robotKey

  )

  $STAction = @()
  # Set up action to run
  $STAction += New-ScheduledTaskAction `
    -Execute 'NET' `
    -Argument 'START "UiRobotSvc"'

  $STAction += New-ScheduledTaskAction `
    -Execute "$robotPath" `
    -Argument "--connect -url  $orcURL -key $robotKey"

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
  $TargetTask.Settings.DeleteExpiredTaskAfter = 'PT5S'
  $TargetTask.Settings.ExecutionTimeLimit = 'PT10M'
  $TargetTask.Settings.volatile = $False

  # Save tweaks to the Scheduled Task
  $TargetTask | Set-ScheduledTask

}

Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
Main
Log-Finish -LogPath $sLogFile