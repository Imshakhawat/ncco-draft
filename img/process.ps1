# Image Processing and JSON Creation Script
# Save this as "Process-Images.ps1"

# Function to convert string to snake_case
function ConvertTo-SnakeCase {
    param([string]$InputString)
    
    # Replace spaces, dots, and hyphens with underscores
    $snake = $InputString -replace '[\s\.\-]+', '_'
    # Convert to lowercase
    $snake = $snake.ToLower()
    # Remove any consecutive underscores
    $snake = $snake -replace '_+', '_'
    # Remove leading/trailing underscores
    $snake = $snake.Trim('_')
    
    return $snake
}

# Create JSON collection
$imageCollection = @()
$index = 1

# Get all image files in current directory
$imageFiles = Get-ChildItem -Path ".\*" -Include "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.tiff", "*.webp" -File

foreach ($file in $imageFiles) {
    try {
        # Get original file info
        $originalName = $file.Name
        $extension = $file.Extension
        $size = $file.Length
        
        # Create snake_case name
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($originalName)
        $snakeName = (ConvertTo-SnakeCase $baseName) + $extension
        
        # Rename the file if the name would change
        if ($originalName -ne $snakeName) {
            $newPath = Join-Path $file.DirectoryName $snakeName
            Rename-Item -Path $file.FullName -NewName $snakeName -Force
            Write-Host "Renamed: $originalName -> $snakeName" -ForegroundColor Green
            $currentFile = Get-Item -Path $newPath
        } else {
            $currentFile = $file
        }
        
        # Get image dimensions (requires .NET)
        try {
            # Load System.Drawing assembly
            Add-Type -AssemblyName System.Drawing
            
            $image = [System.Drawing.Image]::FromFile($currentFile.FullName)
            $width = $image.Width
            $height = $image.Height
            $image.Dispose()
        } catch {
            # If we can't get dimensions, set to null
            $width = $null
            $height = $null
            Write-Warning "Could not get dimensions for: $snakeName"
        }
        
        # Create object for JSON
        $imageObj = [PSCustomObject]@{
            indexno = $index
            originalName = $originalName
            name = $snakeName
            height = $height
            width = $width
            type = $extension.TrimStart('.')
            url = "./$snakeName"  # Relative URL
            size = $size
            sizeKB = [math]::Round($size / 1KB, 2)
            lastModified = $currentFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        # Add to collection
        $imageCollection += $imageObj
        $index++
        
    } catch {
        Write-Error "Error processing file: $($file.Name). Error: $_"
    }
}

# Convert collection to JSON
$jsonOutput = $imageCollection | ConvertTo-Json -Depth 3

# Save JSON to file
$jsonOutput | Out-File -FilePath "images_collection.json" -Encoding UTF8
Write-Host "`nJSON collection saved to: images_collection.json" -ForegroundColor Cyan

# Display summary
Write-Host "`n=== Processing Summary ===" -ForegroundColor Yellow
Write-Host "Total images processed: $($imageCollection.Count)"
Write-Host "JSON file created: images_collection.json"
Write-Host "`nSample of first item:" -ForegroundColor Cyan
if ($imageCollection.Count -gt 0) {
    $imageCollection[0] | Format-List | Out-String | Write-Host
}