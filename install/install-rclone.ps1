# 1. Fetch rclone versions
$HTML = Invoke-WebRequest "https://downloads.rclone.org/"
$VERSIONS = [regex]::Matches($HTML.Content, '>(v\d+\.\d+\.\d+)/<') | ForEach-Object { $_.Groups[1].Value }
$VERSIONS = $VERSIONS | Sort-Object { [version]($_ -replace '^v','') }

# 2. Show menu (option 0 is "latest")
Write-Host "Available rclone versions:"
Write-Host "0: Latest ($($VERSIONS[-1]))"
for ($I=0; $I -lt $VERSIONS.Count; $I++) {
    Write-Host "$($I+1): $($VERSIONS[$I])"
}

$SELECTION = Read-Host "Enter the number of the version you want to install (0 for latest, blank for latest)"
if ([string]::IsNullOrWhiteSpace($SELECTION) -or $SELECTION -eq "0") {
    $RCLONE_VERSION = $VERSIONS[-1]
} else {
    $INDEX = [int]$SELECTION - 1
    if ($INDEX -lt 0 -or $INDEX -ge $VERSIONS.Count) {
        Write-Host "Invalid selection. Exiting."
        exit 1
    }
    $RCLONE_VERSION = $VERSIONS[$INDEX]
}
Write-Host "Selected version: $RCLONE_VERSION"

# 3. Prepare destination folder
$BINPATH = "$HOME\.local\bin"
if (!(Test-Path -Path $BINPATH)) {
    New-Item -ItemType Directory -Path $BINPATH -Force | Out-Null
}

# 4. Add $HOME\.local\bin to user PATH if not already present
$CURRENTPATH = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($CURRENTPATH -notlike "*$BINPATH*") {
    [Environment]::SetEnvironmentVariable("PATH", "$CURRENTPATH;$BINPATH", "User")
    Write-Host "Added $BINPATH to user PATH. You may need to restart your terminal."
}

# 5. Download and extract rclone
$RCLONE_URL = "https://downloads.rclone.org/$RCLONE_VERSION/rclone-$RCLONE_VERSION-windows-amd64.zip"
Write-Host "Downloading rclone from: $RCLONE_URL"
$RCLONE_ZIP = Join-Path $BINPATH "rclone-$RCLONE_VERSION-windows-amd64.zip"

Invoke-WebRequest $RCLONE_URL -OutFile $RCLONE_ZIP
Expand-Archive -Path $RCLONE_ZIP -DestinationPath $BINPATH -Force

# 6. Cleanup: Copy rclone.exe to bin, remove folder/zip
Copy-Item "$BINPATH\rclone-$RCLONE_VERSION-windows-amd64\rclone.exe" $BINPATH -Force
Remove-Item "$BINPATH\rclone-$RCLONE_VERSION-windows-amd64" -Recurse -Force
Remove-Item "$BINPATH\rclone-$RCLONE_VERSION-windows-amd64.zip" -Force

Write-Host "All done! rclone $RCLONE_VERSION should now be extracted in $BINPATH"
