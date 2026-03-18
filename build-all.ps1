#!/usr/bin/env pwsh

# DOHRelay Multi-Platform Build Script (Windows PowerShell)
# Builds DOHRelay for multiple architectures and creates archives

param(
    [ValidateSet("all", "win-x64", "win-x86", "win-arm64", "linux-x64", "linux-arm64", "osx-x64", "osx-arm64")]
    [string]$Platform = "all",
    
    [switch]$SelfContained = $true
)

$ErrorActionPreference = "Stop"

# Color output
$Green = @{ ForegroundColor = "Green" }
$Red = @{ ForegroundColor = "Red" }
$Yellow = @{ ForegroundColor = "Yellow" }

Write-Host "DOHRelay Multi-Platform Build Script" @Green

# Determine which platforms to build
$buildMatrix = @(
    @{ RID = "win-x64"; Name = "Windows x86-64"; Ext = "zip" }
    @{ RID = "win-x86"; Name = "Windows x86"; Ext = "zip" }
    @{ RID = "win-arm64"; Name = "Windows ARM64"; Ext = "zip" }
    @{ RID = "linux-x64"; Name = "Linux x86-64"; Ext = "tar.gz" }
    @{ RID = "linux-arm64"; Name = "Linux ARM64"; Ext = "tar.gz" }
    @{ RID = "osx-x64"; Name = "macOS x86-64"; Ext = "tar.gz" }
    @{ RID = "osx-arm64"; Name = "macOS ARM64"; Ext = "tar.gz" }
)

if ($Platform -ne "all") {
    $buildMatrix = $buildMatrix | Where-Object { $_.RID -eq $Platform }
}

# Create output directory
$outputDir = ".\artifacts"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$successCount = 0
$failCount = 0

# Build for each platform
foreach ($platform in $buildMatrix) {
    $rid = $platform.RID
    $name = $platform.Name
    $ext = $platform.Ext
    
    Write-Host "`nBuilding for $name ($rid)..." @Yellow
    
    try {
        # Clean previous build
        if (Test-Path "bin/Release/net8.0/$rid") {
            Remove-Item -Path "bin/Release/net8.0/$rid" -Recurse -Force
        }
        
        # Publish
        $publishArgs = @(
            "publish"
            "-c", "Release"
            "-r", $rid
            "--no-restore"
            "-o", ".\publish_$rid"
        )
        
        if ($SelfContained) {
            $publishArgs += "--self-contained"
        }
        
        Write-Host "  Publishing..." 
        & dotnet @publishArgs | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Publish failed for $rid"
        }
        
        # Create archive
        Write-Host "  Creating archive..."
        $archiveName = "DOHRelay-$rid"
        
        if ($ext -eq "zip") {
            $zipPath = "$outputDir\$archiveName.zip"
            Compress-Archive -Path ".\publish_$rid\*" -DestinationPath $zipPath -Force
            Write-Host "✓ Created: $zipPath" @Green
        } else {
            # Create tar.gz
            $tarFileName = "$archiveName.tar.gz"
            $tarPath = "$outputDir\$tarFileName"
            
            # Navigate to publish directory and create tar
            Push-Location ".\publish_$rid"
            
            # Use tar on Windows 10+
            & tar czf "..\$tarPath" . 2>$null
            
            Pop-Location
            Write-Host "✓ Created: $tarPath" @Green
        }
        
        # Cleanup
        Remove-Item -Path ".\publish_$rid" -Recurse -Force -ErrorAction SilentlyContinue
        
        $successCount++
    }
    catch {
        Write-Host "✗ Build failed: $_" @Red
        $failCount++
    }
}

# Summary
Write-Host "`n" + ("=" * 50) @Yellow
Write-Host "Build Summary" @Green
Write-Host "  Successful: $successCount" @Green
Write-Host "  Failed: $failCount" $(if ($failCount -gt 0) { @Red } else { @Green })
Write-Host "  Output directory: $outputDir" @Green
Write-Host "=" * 50 @Yellow

if ($failCount -eq 0) {
    Write-Host "`n✓ All builds completed successfully!" @Green
    exit 0
} else {
    Write-Host "`n✗ Some builds failed!" @Red
    exit 1
}
