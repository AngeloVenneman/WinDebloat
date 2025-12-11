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
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
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
If (Test-Path $WinDebloat) {
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
#   Collect Appx before debloat                                                 #
#                                                                               #
#################################################################################

$machine = $env:COMPUTERNAME
$manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer -replace '[^\w]', ''
if ([string]::IsNullOrWhiteSpace($manufacturer)) { $manufacturer = "Unknown" }

$appxList = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty Name | Sort-Object -Unique

# Include manufacturer in the filename: MACHINE_MANUFACTURER.json
$fileName = "$manufacturer - $machine.json"
$filePath = Join-Path $WinDebloat $fileName

$appxList | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath

Write-Output "AppX list saved for $machine ($manufacturer) → $fileName"

#################################################################################
#                                                                               #
#    Export Traditional Programs from Registry                                  #
#                                                                               #
#################################################################################

# Registry keys to export
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Output folder
$exportFolder = "C:\WinDebloat\RegistryExports"
if (-not (Test-Path $exportFolder)) { New-Item -ItemType Directory -Path $exportFolder }

foreach ($key in $uninstallKeys) {
    $keyName = ($key -replace "[:\\]", "_") + ".reg.json"  # Convert to safe filename
    $exportPath = Join-Path $exportFolder $keyName

    # Get all subkeys and their properties
    $allApps = Get-ChildItem $key -ErrorAction SilentlyContinue | ForEach-Object {
        $props = Get-ItemProperty $_.PsPath
        # Export only relevant properties
        [PSCustomObject]@{
            DisplayName = $props.DisplayName
            DisplayVersion = $props.DisplayVersion
            Publisher = $props.Publisher
            InstallLocation = $props.InstallLocation
            UninstallString = $props.UninstallString
        }
    }

    # Save to JSON
    $allApps | ConvertTo-Json -Depth 5 | Set-Content -Path $exportPath
    Write-Output "Exported $key to $exportPath"
}

#################################################################################
#                                                                               #
#    AppX Packages                                                              #
#                                                                               #
#################################################################################

$appxtoremove = @(
    ""
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

################################################################################
#                                                                              #
#    Traditional Packages                                                      #
#                                                                              #
################################################################################

# Specify the uninstall command for the program - Uninstaller found at these registery paths:
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
# HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
$programs = @(
    @{ Name=""; Path=""; Args="" }
)

foreach ($p in $programs) {
    if (Test-Path $p.Path) {
        Write-Output "Uninstalling $($p.Name) silently..."
        Start-Process -FilePath $p.Path -ArgumentList $p.Args -Wait -WindowStyle Hidden
        Write-Output "$($p.Name) uninstall attempted."
    } else {
        Write-Output "$($p.Name) not found at $($p.Path)"
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



#################################################################################
#                                                                               #
#     END                                                                       #
#                                                                               #
#################################################################################

write-output "Completed"