Write-Output "__          ___       _____       _     _             _   "
Write-Output "\ \        / (_)     |  __ \     | |   | |           | |  "
Write-Output " \ \  /\  / / _ _ __ | |  | | ___| |__ | | ___   __ _| |_ "
Write-Output "  \ \/  \/ / | | '_ \| |  | |/ _ \ '_ \| |/ _ \ / _` | __|"
Write-Output "   \  /\  /  | | | | | |__| |  __/ |_) | | (_) | (_| | |_ "
Write-Output "    \/  \/   |_|_| |_|_____/ \___|_.__/|_|\___/ \__,_|\__|"
Write-Output ""
Write-Output "                                                       by Angelo Venneman"
Write-Output ""
Write-Output ""

#################################################################################
#                                                                               #
#   Run As Administrator                                                        #
#                                                                               #
#################################################################################

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Output "This script needs to run as Administrator.`nThis script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    for ($i = 3; $i -ge 1; $i--) {
        Write-Host -NoNewline "$i... "
        Start-Sleep 1
    }
    Write-Host ""  # newline
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -customwhitelist {1} -TasksToRemove {2}" -f $PSCommandPath, ($customwhitelist -join ','), ($TasksToRemove -join ',')) -Verb RunAs
    Exit
}

#################################################################################
#                                                                               #
#   Initialize Script Variables                                                 #
#                                                                               #
#################################################################################

$ErrorActionPreference = 'silentlycontinue' # Suppress non-terminating errors
$ProgressPreference = 'SilentlyContinue' # Suppress progress bars

#################################################################################
#                                                                               #
#   Create WinDebloat folder                                                    #
#                                                                               #
#################################################################################

$WinDebloat = "$env:SystemDrive\WinDebloat"
If (Test-Path -Path $WinDebloat) {
    Write-Output "WinDebloat folder already exists."
}
Else {
    New-Item -Path $WinDebloat -ItemType Directory
    Write-Output "Created WinDebloat folder at $WinDebloat"
}

#################################################################################
#                                                                               #
#   Start Transcript (Logging)                                                  #
#                                                                               #
#################################################################################

Write-Output "" 
Start-Transcript -Path "$WinDebloat\WinDebloat_Log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
Write-Output ""

#################################################################################
#                                                                               #
#    AppX Packages                                                        #
#                                                                               #
#################################################################################

$appxtoremove = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingFinance",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MSPaint",
    "Microsoft.News",
    "Microsoft.Office.OneNote",
    "Microsoft.OneConnect",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.SolitaireCollection",
    "Microsoft.Wallet",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

$appxinstalled = Get-AppxPackage -AllUsers | Where-Object { $appxtoremove -contains $_.Name }
foreach ($appxapp in $appxinstalled) {
    $packagename = $appxapp.PackageFullName
    $displayname = $appxapp.Name
    write-output "$displayname AppX Package exists"
    write-output "Removing $displayname AppX Package"
    try {
        Remove-AppxPackage -Package $packagename -AllUsers -ErrorAction SilentlyContinue
        write-output "Removed $displayname AppX Package"
    }
    catch {
        write-output "$displayname AppX Package does not exist"
    }
}

#################################################################################
#                                                                               #
#   Detect Manufacturer                                                         #
#                                                                               #
#################################################################################

write-output "Detecting Manufacturer"
$details = Get-CimInstance -ClassName Win32_ComputerSystem
$manufacturer = $details.Manufacturer

#################################################################################
#                                                                               #
#   Remove HP Bloat                                                             #
#                                                                               #
#################################################################################

if ($manufacturer -like "*HP*") {
    write-output "HP detected"
    # Remove HP bloat
}

#################################################################################
#                                                                               #
#    Remove Dell Bloat                                                          #
#                                                                               #
#################################################################################

if ($manufacturer -like "*Dell*") {
    write-output "Dell detected"
    # Dell bloat
}

#################################################################################
#                                                                               #
#    Remove Lenovo Bloat                                                        #
#                                                                               #
#################################################################################

if ($manufacturer -like "Lenovo") {
    write-output "Lenovo detected"
}

#################################################################################
#                                                                               #
#     Remove other programs                                                     #
#                                                                               #
#################################################################################


write-output "Completed"