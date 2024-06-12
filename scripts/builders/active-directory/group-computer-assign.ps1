# Powershell Script for Assigning Users and Group to Computers with HR in Name on a Domain Controller
# Modify $targetGroup and $computerList as needed 

Import-Module ActiveDirectory

$targetGroup = "group@domain.root"
$userList = Get-ADGroupMember -Identity $targetGroup | Select-Object -ExpandProperty SamAccountName
$computerList = Get-ADComputer -Filter { Name -like "*group*" } | Select-Object -ExpandProperty Name

foreach ($computer in $computerList) {
    foreach ($user in $userList) {
        try {
            Add-ADGroupManagedServiceAccountMember -Identity $targetGroup -Member $user -ComputerName $computer -ErrorAction Stop
            Write-Output "Successfully added user to group assigned to computer: $user on $computer"
        } catch {
            Write-Warning "Failed to add user $user to computer $computer. Error: $_"
        }
    }
}