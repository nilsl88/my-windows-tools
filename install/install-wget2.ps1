<#
    wget2 Windows Installer Script

    - Checks GitHub releases for Windows builds (looks for "win" or "exe" in asset names)
    - Lets you pick a version if any are found
    - Downloads and extracts/copies wget2.exe to $HOME\.local\bin
    - Adds $HOME\.local\bin to PATH if needed
    - Cleans up after itself
    - If nothing is found, offers next steps for Windows users
#>

# 1. Fetch wget2 releases from GitHub
$RELEASES_URL = "https://api.github.com/repos/rockdaboot/wget2/releases"
try {
    $RELEASES = Invoke-RestMethod -Uri $RELEASES_URL
} catch {
    Write-Host "Could not fetch releases from GitHub. Check your internet connection."
    exit 1
}

# 2. Find potential Windows assets
$ASSETS = @()
foreach ($rel in $RELEASES) {
    foreach ($asset in $rel.assets) {
        if ($asset.name -match '(?i)(win|windows).*\.zip$' -or $asset.name -match '(?i)wget2.*\.exe$') {
            $ASSETS += [PSCustomObject]@{
                tag = $rel.tag_name
                asset = $asset
            }
        }
    }
}

if (!$ASSETS -or $ASSETS.Count -eq 0) {
    Write-Host "`nNo official Windows binaries found for wget2 on GitHub releases."
    Write-Host "You have these options:"
    Write-Host "- Build wget2 from source using MSYS2 or Cygwin"
    Write-Host "- Search online for unofficial builds (careful: always scan for malware)"
    Write-Host "- Or use classic wget (https://eternallybored.org/misc/wget/)"
    Write-Host "- Or try MSYS2: 'pacman -S mingw-w64-ucrt-x86_64-wget2'"
    exit 1
}

# 3. Show user menu
Write-Host "`nFound the following possible Windows wget2 releases:"
Write-Host ("0: Latest ({0}) - {1}" -f $ASSETS[-1].tag, $ASSETS[-1].asset.name)
for ($I=0; $I -lt $ASSETS.Count; $I++) {
    Write-Host ("{0}: {1} - {2}" -f ($I+1), $ASSETS[$I].tag, $ASSETS[$I].asset.name)
}

$SELECTION = Read-Host "`nEnter the number of the version you want to install (0 for latest, blank for latest)"
if ([string]::IsNullOrWhiteSpace($SELECTION) -or $SELECTION -eq "0") {
    $SEL = $ASSETS[-1]
} else {
    $INDEX = [int]$SELECTION - 1
    if ($INDEX -lt 0 -or $INDEX -ge $ASSETS.Count) {
        Write-Host "Invalid selection. Exiting."
        exit 1
    }
    $SEL = $ASSETS[$INDEX]
}
Write-Host ("Selected: {0} - {1}" -f $SEL.tag, $SEL.asset.name)

# 4. Prepare bin directory
$BINPATH = "$HOME\.local\bin"
if (!(Test-Path -Path $BINPATH)) {
    New-Item -ItemType Directory -Path $BINPATH -Force | Out-Null
}

# 5. Add to PATH if needed
$CURRENTPATH = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($CURRENTPATH -notlike "*$BINPATH*") {
    [Environment]::SetEnvironmentVariable("PATH", "$CURRENTPATH;$BINPATH", "User")
    Write-Host "Added $BINPATH to user PATH. You may need to restart your terminal."
}

# 6. Download and extract/copy
$FILENAME = $SEL.asset.name
$DOWNLOAD_URL = $SEL.asset.browser_download_url
$DOWNLOAD_PATH = Join-Path $BINPATH $FILENAME

Write-Host ("Downloading: {0}" -f $DOWNLOAD_URL)
Invoke-WebRequest $DOWNLOAD_URL -OutFile $DOWNLOAD_PATH

if ($FILENAME -like "*.zip") {
    Expand-Archive -Path $DOWNLOAD_PATH -DestinationPath $BINPATH -Force
    $EXE = Get-ChildItem -Path $BINPATH -Recurse -Filter wget2.exe | Select-Object -First 1
    if ($EXE) {
        Copy-Item $EXE.FullName $BINPATH -Force
        $EXTRACTED = $EXE.Directory.FullName
        if ($EXTRACTED -ne $BINPATH) {
            Remove-Item $EXTRACTED -Recurse -Force
        }
    } else {
        Write-Host "Could not find wget2.exe after extraction. Please check manually."
        exit 1
    }
    Remove-Item $DOWNLOAD_PATH -Force
} elseif ($FILENAME -like "*.exe") {
    $DEST = "$BINPATH\wget2.exe"
    # If the download path and destination path are the same, do nothing
    if ((Resolve-Path $DOWNLOAD_PATH).Path -eq (Resolve-Path $DEST).Path) {
        Write-Host "wget2.exe is already in $BINPATH"
        # Nothing more to do
    } else {
        # Remove destination if it exists
        if (Test-Path $DEST) { Remove-Item $DEST -Force }
        Copy-Item $DOWNLOAD_PATH $DEST
        Remove-Item $DOWNLOAD_PATH -Force
    }
} else {
    Write-Host "Downloaded file is not a .zip or .exe. Please check manually."
    exit 1
}

Write-Host ("All done! wget2 ({0}) should now be in {1}" -f $SEL.tag, $BINPATH)
Write-Host "Open a new terminal or restart your session if wget2 is not found in PATH."
