Add-Type -AssemblyName System.Windows.Forms

$SFTAPath = Join-Path $PSScriptRoot "PS-SFTA\SFTA.ps1"
$VideoFormatsFilePath = Join-Path $PSScriptRoot "formats_videos.txt"
$ImageFormatsFilePath = Join-Path $PSScriptRoot "formats_images.txt"
$imageExtensions = Get-Content $ImageFormatsFilePath | ForEach-Object { ".$_" }
$videoExtensions = Get-Content $VideoFormatsFilePath | ForEach-Object { ".$_" }

. $SFTAPath

function Select-Application([string]$Title) {

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = "Programs (*.exe)|*.exe"
    $dialog.InitialDirectory = $env:ProgramFiles
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false

    $result = $dialog.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    return $dialog.FileName
}

# Select image viewer

$imageExePath = Select-Application "Choose the default image viewer"
$imageExeName = Split-Path -Path $imageExePath -Leaf
Write-Host "Selected image viewer: $imageExePath"

# Select video player

$videoExePath = Select-Application "Choose the default video player"
$videoExeName = Split-Path -Path $videoExePath -Leaf
Write-Host "Selected video player: $videoExePath"

# Set the image extensions

foreach ($extension in $imageExtensions) {

    Write-Host "Setting $extension to $imageExeName"
    Set-FTA "Applications\$imageExeName" $extension
}

# Set the video extensions

foreach ($extension in $videoExtensions) {
    Write-Host "Setting $extension to $videoExeName"
    Set-FTA "Applications\$videoExeName" $extension
}