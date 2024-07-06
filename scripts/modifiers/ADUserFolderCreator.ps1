# PowerShell Script: ADComputerUserFolderCreator.ps1
# Usage: .\ADComputerUserFolderCreator.ps1 -DomainName "domain.root" -Credentials (Get-Credential)

<#
.SYNOPSIS 
This function identifies computers on an Active Directory (AD) domain, checks their local security groups, retrieves users in each group, and creates a folder structure for any user missing within "C:\Users\" on each computer in the domain.
#>

function New-UserDirectories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DomainName,
        
        [Parameter(Mandatory)]
        [PSCredential]$Credentials
    )

    # Import necessary modules for AD interaction
    Import-Module ActiveDirectory

    Write-Host "Identifying computers on the domain and managing user folders:"

    try {
        # Get all computers in the specified domain
        $allComputersInDomain = Get-ADComputer -Filter * -Server $DomainName | Select-Object Name, DistinguishedName

        foreach ($computer in $allComputersInDomain) {
            $computerName = $computer.Name
            Write-Host "`nProcessing computer: $computerName"
            
            # Create a session to connect to the remote computer
            $session = New-PSSession -ComputerName $computerName -Credential $Credentials
            try {
                # Get all local security groups for the remote computer
                $localSecurityGroups = Invoke-Command -Session $session -ScriptBlock {
                    Get-LocalGroup -Name '*' -ErrorAction SilentlyContinue | Where-Object { $_.ObjectClass -eq "group" }
                }

                foreach ($group in $localSecurityGroups) {
                    Write-Host "`nProcessing security group: $($group.Name)"
                    
                    # Retrieve users within the local security groups
                    $users = Invoke-Command -Session $session -ScriptBlock {
                        param($groupName)
                        Get-LocalGroupMember -Group $groupName | Where-Object { $_.ObjectClass -eq "user" }
                    } -ArgumentList $group.Name

                    foreach ($user in $users) {
                        $username = $user.Name
                        $dirPath = "C:\Users\$username"

                        # Check if the directory exists, if not, create it
                        $dirExists = Invoke-Command -Session $session -ScriptBlock {
                            param($path)
                            Test-Path -Path $path
                        } -ArgumentList $dirPath

                        if (-not $dirExists) {
                            Write-Host "Creating directory for user: $username on $computerName"
                            Invoke-Command -Session $session -ScriptBlock {
                                param($path)
                                New-Item -ItemType Directory -Path $path
                            } -ArgumentList $dirPath
                        } else {
                            Write-Host "Directory for user: $username already exists on $computerName"
                        }
                    }
                }
            } catch {
                Write-Error "An error occurred while processing $computerName: $_"
            } finally {
                # Close the session
                Remove-PSSession -Session $session
            }
        }
    } catch {
        Write-Error "An error occurred during processing: $_"
    }
}

# Example usage
# New-UserDirectories -DomainName "domain.root" -Credentials (Get-Credential)
