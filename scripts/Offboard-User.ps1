# Offboard-User.ps1
# Offboards a departing user: saves a record of their groups, scrambles the password,
# disables the account, documents the change, removes group memberships, and moves
# the account to the Disabled Users OU. Disables rather than deletes, so the SID and
# history are preserved.
# Usage: .\Offboard-User.ps1 -Username ohaddad -Ticket HD-1042
# Homelab Entry 27 - homelab.local

param(
    [Parameter(Mandatory)][string]$Username,
    [Parameter(Mandatory)][string]$Ticket
)

$user = Get-ADUser -Filter "SamAccountName -eq '$Username'" -Properties Title
if (-not $user) {
    Write-Host "User $Username not found - nothing changed" -ForegroundColor Red
    return
}

$date   = Get-Date -Format yyyy-MM-dd
$logDir = "C:/Scripts/offboarding"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

try {
    # 1. Record group memberships before removing anything
    $groups = Get-ADPrincipalGroupMembership $Username -ErrorAction Stop | Where-Object { $_.Name -ne "Domain Users" }
    $groups | Select-Object @{n="User";e={$Username}}, Name, @{n="Ticket";e={$Ticket}}, @{n="Date";e={$date}} |
        Export-Csv "$logDir/$Username-$date-groups.csv" -NoTypeInformation

    # 2. Scramble the password so any password the user still knows stops working
    $chars  = 'ABCDEFGHJKLMNPQRSTUVWXabcdefghjkmnpqrstuvwx23456789'
    $random = -join (1..24 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    Set-ADAccountPassword $Username -Reset -NewPassword (ConvertTo-SecureString $random -AsPlainText -Force) -ErrorAction Stop

    # 3. Disable and document
    Disable-ADAccount $Username -ErrorAction Stop
    Set-ADUser $Username -Description "Offboarded $date by $env:USERNAME - ticket $Ticket - former $($user.Title)" -ErrorAction Stop

    # 4. Remove group memberships (Domain Users is the primary group and stays)
    foreach ($g in $groups) { Remove-ADGroupMember -Identity $g -Members $Username -Confirm:$false -ErrorAction Stop }

    # 5. Move to the Disabled Users OU
    Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Disabled Users,DC=homelab,DC=local" -ErrorAction Stop

    Write-Host "Offboarded $Username (ticket $Ticket): password scrambled, disabled, $(@($groups).Count) group(s) removed, moved to Disabled Users" -ForegroundColor Green
    Write-Host "Group record saved to $logDir/$Username-$date-groups.csv" -ForegroundColor Yellow
}
catch {
    Write-Host "FAILED offboarding $Username : $($_.Exception.Message)" -ForegroundColor Red
}
