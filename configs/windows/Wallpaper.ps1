# Prompt the user for a wallpaper style
$style = Read-Host "Enter the desired wallpaper style (Fit, Center, Span)"

# Define registry path
$RegistryPath = "HKCU:\Control Panel\Desktop"

# Set registry values based on user input
switch ($style.ToLower()) {
    "fit" {
        Set-ItemProperty -Path $RegistryPath -Name "WallpaperStyle" -Value "6"
        Set-ItemProperty -Path $RegistryPath -Name "TileWallpaper" -Value "0"
        Write-Host "Wallpaper style set to Fit"
    }
    "center" {
        Set-ItemProperty -Path $RegistryPath -Name "WallpaperStyle" -Value "0"
        Set-ItemProperty -Path $RegistryPath -Name "TileWallpaper" -Value "0"
        Write-Host "Wallpaper style set to Center"
    }
    "span" {
        Set-ItemProperty -Path $RegistryPath -Name "WallpaperStyle" -Value "22"
        Set-ItemProperty -Path $RegistryPath -Name "TileWallpaper" -Value "0"
        Write-Host "Wallpaper style set to Span"
    }
    Default {
        Write-Host "Invalid input. Please enter Fit, Center, or Span."
    }
}

# Apply changes
RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters
