# New-Hires.ps1 (v2)
# Bulk-creates Active Directory users from a CSV (FirstName, LastName, Department, Title).
# Each hire gets a unique random temporary password, is placed in their department OU,
# added to "<Department> Team", and must change the password at first sign-in.
# Usernames and temporary passwords are written to a timestamped handoff file:
# deliver it securely, then delete it.
# Homelab Entry 27 - homelab.local

param([string]$CsvPath = "C:/Scripts/newhires.csv")

function New-TempPassword {
    # 4 uppercase + 4 lowercase + 4 digits, shuffled. Excludes 0/O, 1/l/I and Y/Z.
    $sets = 'ABCDEFGHJKLMNPQRSTUVWX', 'abcdefghjkmnpqrstuvwx', '23456789'
    $chars = foreach ($set in $sets) { 1..4 | ForEach-Object { $set[(Get-Random -Maximum $set.Length)] } }
    -join ($chars | Sort-Object { Get-Random })
}

$results = @()
Import-Csv $CsvPath | ForEach-Object {
    $sam = ($_.FirstName.Substring(0,1) + $_.LastName).ToLower()
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Warning "$sam already exists - skipped"
        return
    }
    $plain = New-TempPassword
    $params = @{
        Name                  = "$($_.FirstName) $($_.LastName)"
        GivenName             = $_.FirstName
        Surname               = $_.LastName
        SamAccountName        = $sam
        UserPrincipalName     = "$sam@homelab.local"
        Title                 = $_.Title
        Department            = $_.Department
        Path                  = "OU=$($_.Department),DC=homelab,DC=local"
        AccountPassword       = (ConvertTo-SecureString $plain -AsPlainText -Force)
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }
    try {
        New-ADUser @params -ErrorAction Stop
        Add-ADGroupMember -Identity "$($_.Department) Team" -Members $sam -ErrorAction Stop
        $results += [pscustomobject]@{ Name = $params.Name; Username = $sam; Department = $_.Department; TempPassword = $plain }
        Write-Host "Created $sam in $($_.Department), added to $($_.Department) Team" -ForegroundColor Green
    }
    catch {
        Write-Host "FAILED for $sam : $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($results.Count -gt 0) {
    $out = "C:/Scripts/handoff/newhires-$(Get-Date -Format yyyy-MM-dd-HHmm).csv"
    $results | Export-Csv $out -NoTypeInformation
    Write-Host "Handoff file: $out - deliver securely, then delete it" -ForegroundColor Yellow
}
