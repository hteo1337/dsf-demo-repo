Add-MpPreference -ExclusionPath "C:\Temp"

$TargetFile = "$env:SystemRoot\System32\cmd.exe"
$ShortcutFile = "$env:Public\Desktop\ProvisionRobot.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = " /C C:\Temp\ModernRobotProvisioning.exe"
$Shortcut.Save()


$TargetFile = "$env:SystemRoot\System32\cmd.exe"
$ShortcutFile = "$env:Public\Desktop\DeprovisionRobot.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = " /C C:\Temp\ModernRobotProvisioning.exe -dp"
$Shortcut.Save()

