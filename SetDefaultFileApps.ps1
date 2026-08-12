Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# Configuration
# ============================================================

$SFTAPath = Join-Path $PSScriptRoot "PS-SFTA\SFTA.ps1"
. $SFTAPath

$VideoFormatsFilePath = Join-Path $PSScriptRoot "formats_videos.txt"
$ImageFormatsFilePath = Join-Path $PSScriptRoot "formats_images.txt"
$imageExtensions = Get-Content $ImageFormatsFilePath | ForEach-Object { ".$_" }
$videoExtensions = Get-Content $VideoFormatsFilePath | ForEach-Object { ".$_" }

# ============================================================
# Check SFTA.ps1
# ============================================================

if (-not (Test-Path -LiteralPath $SFTAPath)) {

    [System.Windows.Forms.MessageBox]::Show(
        "SFTA.ps1 was not found:`n`n$SFTAPath`n`nDownload it from the PS-SFTA GitHub repository and place it next to this script.",
        "SFTA.ps1 not found",
        "OK",
        "Error"
    )

    exit 1
}

# Load SFTA functions
. $SFTAPath

# ============================================================
# Function: Select EXE
# ============================================================

function Select-Application {

    param (
        [string]$Title
    )

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

# ============================================================
# Select image viewer
# ============================================================

$imageExePath = Select-Application "Choose the default image viewer"

if (-not $imageExePath) {
    Write-Host "Cancelled."
    exit 0
}

$imageExeName = Split-Path -Path $imageExePath -Leaf

Write-Host ""
Write-Host "Selected image viewer:"
Write-Host "  $imageExePath"
Write-Host ""

# ============================================================
# Select video player
# ============================================================

$videoExePath = Select-Application "Choose the default video player"

if (-not $videoExePath) {
    Write-Host "Cancelled."
    exit 0
}

$videoExeName = Split-Path -Path $videoExePath -Leaf

Write-Host ""
Write-Host "Selected video player:"
Write-Host "  $videoExePath"
Write-Host ""

# ============================================================
# Confirm everything
# ============================================================

$confirmation = @"
IMAGE VIEWER
$imageExePath

$($imageExtensions.Count) image formats:
$($imageExtensions -join ", ")


VIDEO PLAYER
$videoExePath

$($videoExtensions.Count) video formats:
$($videoExtensions -join ", ")


Continue?
"@

$answer = [System.Windows.Forms.MessageBox]::Show(
    $confirmation,
    "Set default applications",
    "YesNo",
    "Question"
)

if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
    Write-Host "Cancelled."
    exit 0
}

# ============================================================
# Register image application and set associations
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "IMAGE ASSOCIATIONS"
Write-Host "========================================"
Write-Host ""
Write-Host "Application: $imageExePath"
Write-Host ""

$imageSuccessCount = 0
$imageFailedCount = 0

# Register the application using the first image extension.
# Register-FTA creates the application registration and
# sets the selected extension at the same time.

try {

    Write-Host "Registering application with $($imageExtensions[0])..."

    Register-FTA $imageExePath $imageExtensions[0]

    $imageSuccessCount++

}
catch {

    Write-Warning "Failed to register image application:"
    Write-Warning $_.Exception.Message

    $imageFailedCount++
}

# Set the remaining extensions

foreach ($extension in $imageExtensions | Select-Object -Skip 1) {

    Write-Host "Setting $extension -> $imageExeName"

    try {

        Set-FTA "Applications\$imageExeName" $extension

        $imageSuccessCount++

    }
    catch {

        $imageFailedCount++

        Write-Warning "Failed to set $extension"
        Write-Warning $_.Exception.Message
    }
}

# ============================================================
# Register video application and set associations
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "VIDEO ASSOCIATIONS"
Write-Host "========================================"
Write-Host ""
Write-Host "Application: $videoExePath"
Write-Host ""

$videoSuccessCount = 0
$videoFailedCount = 0

# Register the application using the first video extension

try {

    Write-Host "Registering application with $($videoExtensions[0])..."

    Register-FTA $videoExePath $videoExtensions[0]

    $videoSuccessCount++

}
catch {

    Write-Warning "Failed to register video application:"
    Write-Warning $_.Exception.Message

    $videoFailedCount++
}

# Set the remaining extensions

foreach ($extension in $videoExtensions | Select-Object -Skip 1) {

    Write-Host "Setting $extension -> $videoExeName"

    try {

        Set-FTA "Applications\$videoExeName" $extension

        $videoSuccessCount++

    }
    catch {

        $videoFailedCount++

        Write-Warning "Failed to set $extension"
        Write-Warning $_.Exception.Message
    }
}

# ============================================================
# Summary
# ============================================================

Write-Host ""
Write-Host "========================================"
Write-Host "SUMMARY"
Write-Host "========================================"
Write-Host ""

Write-Host "Image viewer:"
Write-Host "  $imageExePath"
Write-Host "  Successful: $imageSuccessCount"
Write-Host "  Failed:     $imageFailedCount"

Write-Host ""

Write-Host "Video player:"
Write-Host "  $videoExePath"
Write-Host "  Successful: $videoSuccessCount"
Write-Host "  Failed:     $videoFailedCount"

Write-Host ""

if (($imageFailedCount -eq 0) -and ($videoFailedCount -eq 0)) {

    [System.Windows.Forms.MessageBox]::Show(
        "All file associations were set successfully.",
        "Finished",
        "OK",
        "Information"
    )

}
else {

    [System.Windows.Forms.MessageBox]::Show(
        "The script finished, but some associations failed.`n`nImage failures: $imageFailedCount`nVideo failures: $videoFailedCount",
        "Finished with errors",
        "OK",
        "Warning"
    )
}

Write-Host "Done!"

Read-Host "Press Enter to exit"