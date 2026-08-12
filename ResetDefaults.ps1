Write-Host "Cleaning old SFTA registrations..." -ForegroundColor Yellow

$VideoFormatsFilePath = Join-Path $PSScriptRoot "formats_videos.txt"
$ImageFormatsFilePath = Join-Path $PSScriptRoot "formats_images.txt"
$imageExtensions = Get-Content $ImageFormatsFilePath | ForEach-Object { ".$_" }
$videoExtensions = Get-Content $VideoFormatsFilePath | ForEach-Object { ".$_" }

# Remove SFTA ProgIDs created under HKCU\Software\Classes
Get-ChildItem "HKCU:\Software\Classes" |
    Where-Object { $_.PSChildName -like "SFTA.*" } |
    ForEach-Object {
        Write-Host "Removing ProgID: $($_.PSChildName)"
        Remove-Item $_.PSPath -Recurse -Force
    }

# Remove per-user UserChoice associations for the extensions
$extensions = $imageExtensions + $videoExtensions

foreach ($extension in $extensions) {
    $extension = $extension.Trim()

    if (-not $extension.StartsWith(".")) {
        $extension = ".$extension"
    }

    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension"

    if (Test-Path $path) {
        Write-Host "Removing UserChoice configuration: $extension"
        Remove-Item $path -Recurse -Force
    }
}