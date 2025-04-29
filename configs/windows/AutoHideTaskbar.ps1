# PowerShell Script to enable Auto-Hide for Windows Taskbar
# Created: 4/28/2025

Write-Host "Setting taskbar to auto-hide..."

# Set registry values for taskbar auto-hide
$explorerKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
$value = (Get-ItemProperty -Path $explorerKey -Name Settings).Settings

# Modify the 8th byte (taskbar settings)
# Setting bit 1 of the 8th byte (index 7 in zero-based array) enables auto-hide
$value[8] = 3  # 3 = Auto-hide enabled (1 = disabled)

# Save the modified settings back to registry
Set-ItemProperty -Path $explorerKey -Name Settings -Value $value

# Restart explorer to apply changes
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer

Write-Host "Taskbar auto-hide has been enabled."
Write-Host "Note: You can run this script with administrator privileges if you encounter permission issues."
