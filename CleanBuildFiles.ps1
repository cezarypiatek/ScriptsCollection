<#
.SYNOPSIS
    Recursively searches for and removes bin and obj directories.

.DESCRIPTION
    This script searches for bin and obj directories in the current or specified path,
    prompts for confirmation before deletion, and provides a summary of space reclaimed.

.PARAMETER Path
    The root path to search. Defaults to current directory.

.EXAMPLE
    .\CleanBuildFiles.ps1
    .\CleanBuildFiles.ps1 -Path "C:\Projects"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path
)

# Ensure path exists
if (-not (Test-Path -Path $Path)) {
    Write-Error "Path '$Path' does not exist."
    exit 1
}

Write-Host "Searching for bin and obj directories in: $Path" -ForegroundColor Cyan
Write-Host ""

# Find all bin and obj directories
$directories = Get-ChildItem -Path $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -eq "bin" -or $_.Name -eq "obj" }

if ($directories.Count -eq 0) {
    Write-Host "No bin or obj directories found." -ForegroundColor Green
    exit 0
}

Write-Host "Found $($directories.Count) director$(if($directories.Count -eq 1){'y'}else{'ies'}) to clean." -ForegroundColor Yellow
Write-Host ""

# Initialize counters
$totalSize = 0
$totalDirsRemoved = 0
$totalFilesRemoved = 0
$yesForAll = $false
$aborted = $false

foreach ($dir in $directories) {
    if ($aborted) {
        break
    }

    # Skip if already deleted (parent might have been deleted)
    if (-not (Test-Path -Path $dir.FullName)) {
        continue
    }

    # Calculate directory size
    $size = 0
    $fileCount = 0
    $dirCount = 0
    
    try {
        $items = Get-ChildItem -Path $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
        $files = $items | Where-Object { -not $_.PSIsContainer }
        $dirs = $items | Where-Object { $_.PSIsContainer }
        
        $fileCount = if ($files) { $files.Count } else { 0 }
        $dirCount = if ($dirs) { $dirs.Count } else { 0 }
        
        $size = ($files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if ($null -eq $size) { $size = 0 }
    }
    catch {
        $size = 0
    }

    # Format size
    $sizeFormatted = if ($size -gt 1GB) {
        "{0:N2} GB" -f ($size / 1GB)
    }
    elseif ($size -gt 1MB) {
        "{0:N2} MB" -f ($size / 1MB)
    }
    elseif ($size -gt 1KB) {
        "{0:N2} KB" -f ($size / 1KB)
    }
    else {
        "$size bytes"
    }

    # Show directory info
    Write-Host "Directory: " -NoNewline
    Write-Host $dir.FullName -ForegroundColor White
    Write-Host "  Size: $sizeFormatted ($fileCount file$(if($fileCount -ne 1){'s'}), $dirCount subdirector$(if($dirCount -ne 1){'ies'}else{'y'}))" -ForegroundColor Gray

    # Ask for confirmation if not "Yes for All"
    $delete = $false
    
    if ($yesForAll) {
        $delete = $true
        Write-Host "  Deleting (Yes for All)..." -ForegroundColor Green
    }
    else {
        Write-Host "  Delete this directory?" -ForegroundColor Yellow
        Write-Host "    [Y] Yes  [A] Yes for All  [S] Skip  [X] Abort" -ForegroundColor Cyan
        
        $validResponse = $false
        while (-not $validResponse) {
            $response = Read-Host "  Choice"
            $response = $response.Trim().ToUpper()
            
            if ($response -eq "Y" -or $response -eq "YES") {
                Write-Host "  -> Yes" -ForegroundColor Green
                $delete = $true
                $validResponse = $true
            }
            elseif ($response -eq "A" -or $response -eq "ALL") {
                Write-Host "  -> Yes for All" -ForegroundColor Green
                $delete = $true
                $yesForAll = $true
                $validResponse = $true
            }
            elseif ($response -eq "S" -or $response -eq "SKIP") {
                Write-Host "  -> Skip" -ForegroundColor Yellow
                $delete = $false
                $validResponse = $true
            }
            elseif ($response -eq "X" -or $response -eq "ABORT") {
                Write-Host "  -> Abort" -ForegroundColor Red
                $delete = $false
                $aborted = $true
                $validResponse = $true
            }
            else {
                Write-Host "  Invalid choice. Please enter Y, A, S, or X." -ForegroundColor Red
            }
        }
    }

    # Delete if confirmed
    if ($delete) {
        try {
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "  Deleted successfully" -ForegroundColor Green
            $totalSize += $size
            $totalDirsRemoved += ($dirCount + 1)  # +1 for the directory itself
            $totalFilesRemoved += $fileCount
        }
        catch {
            Write-Host "  Error deleting: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
}

# Display summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($aborted) {
    Write-Host "Operation aborted by user." -ForegroundColor Red
    Write-Host ""
}

$totalSizeFormatted = if ($totalSize -gt 1GB) {
    "{0:N2} GB" -f ($totalSize / 1GB)
}
elseif ($totalSize -gt 1MB) {
    "{0:N2} MB" -f ($totalSize / 1MB)
}
elseif ($totalSize -gt 1KB) {
    "{0:N2} KB" -f ($totalSize / 1KB)
}
else {
    "$totalSize bytes"
}

Write-Host "Total disk space reclaimed: " -NoNewline
Write-Host $totalSizeFormatted -ForegroundColor Green
Write-Host "Directories removed: " -NoNewline
Write-Host $totalDirsRemoved -ForegroundColor Green
Write-Host "Files removed: " -NoNewline
Write-Host $totalFilesRemoved -ForegroundColor Green
Write-Host ""
