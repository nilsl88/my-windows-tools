# 1. Fetch rclone versions
$html = Invoke-WebRequest "https://downloads.rclone.org/"
$versions = [regex]::Matches($html.Content, '>(v\d+\.\d+\.\d+)/<') | ForEach-Object { $_.Groups[1].Value }
$versions = $versions | Sort-Object { [version]($_ -replace '^v','') }

# 2. Show menu (option 0 is "latest")
Write-Host "Available rclone versions:"
Write-Host "0: Latest ($($versions[-1]))"
for ($i=0; $i -lt $versions.Count; $i++) {
    Write-Host "$($i+1): $($versions[$i])"
}

$selection = Read-Host "Enter the number of the version you want to install (0 for latest, blank for latest)"
if ([string]::IsNullOrWhiteSpace($selection) -or $selection -eq "0") {
    $rcloneVersion = $versions[-1]
} else {
    $index = [int]$selection - 1
    if ($index -lt 0 -or $index -ge $versions.Count) {
        Write-Host "Invalid selection. Exiting."
        exit 1
    }
    $rcloneVersion = $versions[$index]
}
Write-Host "Selected version: $rcloneVersion"

# 3. Prepare destination folder
$binPath = "$HOME\.local\bin"
if (!(Test-Path -Path $binPath)) {
    New-Item -ItemType Directory -Path $binPath -Force | Out-Null
}

# 4. Add $HOME\.local\bin to user PATH if not already present
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$binPath*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$binPath", "User")
    Write-Host "Added $binPath to user PATH. You may need to restart your terminal."
}

# 5. Download and extract rclone
$rcloneUrl = "https://downloads.rclone.org/$rcloneVersion/rclone-$rcloneVersion-windows-amd64.zip"
Write-Host "Downloading rclone from: $rcloneUrl"
$rcloneZip = Join-Path $binPath "rclone-$rcloneVersion-windows-amd64.zip"

Invoke-WebRequest $rcloneUrl -OutFile $rcloneZip
Expand-Archive -Path $rcloneZip -DestinationPath $binPath -Force

# 6. Cleanup: Copy rclone.exe to bin, remove folder/zip
Copy-Item "$binPath\rclone-$rcloneVersion-windows-amd64\rclone.exe" $binPath -Force
Remove-Item "$binPath\rclone-$rcloneVersion-windows-amd64" -Recurse -Force
Remove-Item "$binPath\rclone-$rcloneVersion-windows-amd64.zip" -Force

Write-Host "All done! rclone $rcloneVersion should now be extracted in $binPath"