# New-Hires.ps1
# Bulk-creates Active Directory users from a CSV (FirstName, LastName, Department, Title).
# Places each user in the OU matching their Department, adds them to "<Department> Team",
# and forces a password change at first sign-in.
# Homelab Entry 26 - homelab.local

$tempPw = Read-Host "Temporary password for new hires" -AsSecureString
Import-Csv "C:/Scripts/newhires.csv" | ForEach-Object {
    $sam = ($_.FirstName.Substring(0,1) + $_.LastName).ToLower()
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Warning "$sam already exists - skipped"
        return
    }
    $params = @{
        Name                  = "$($_.FirstName) $($_.LastName)"
        GivenName             = $_.FirstName
        Surname               = $_.LastName
        SamAccountName        = $sam
        UserPrincipalName     = "$sam@homelab.local"
        Title                 = $_.Title
        Department            = $_.Department
        Path                  = "OU=$($_.Department),DC=homelab,DC=local"
        AccountPassword       = $tempPw
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }
    try {
        New-ADUser @params -ErrorAction Stop
        Add-ADGroupMember -Identity "$($_.Department) Team" -Members $sam -ErrorAction Stop
        Write-Host "Created $sam in $($_.Department), added to $($_.Department) Team" -ForegroundColor Green
    }
    catch {
        Write-Host "FAILED for $sam : $($_.Exception.Message)" -ForegroundColor Red
    }
}
