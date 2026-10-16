# Get-AccountAudit.ps1
# Builds an HTML account audit report for the last N days (default 30):
# account changes from the Security log (with who made them), disabled accounts,
# locked-out accounts, new accounts that never completed first sign-in, and
# enabled accounts with no sign-in during the period.
# Usage: .\Get-AccountAudit.ps1            (last 30 days)
#        .\Get-AccountAudit.ps1 -Days 7    (last 7 days)
# Homelab Entry 28 - homelab.local

param([int]$Days = 30)

$since  = (Get-Date).AddDays(-$Days)
$stamp  = Get-Date -Format yyyy-MM-dd
$outDir = "C:/Scripts/reports"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$names = @{
    4720 = "Account created";       4722 = "Account enabled";        4724 = "Password reset"
    4725 = "Account disabled";      4726 = "Account deleted";        4740 = "Account locked out"
    4767 = "Account unlocked";      4728 = "Added to global group";  4729 = "Removed from global group"
    4732 = "Added to local group";  4733 = "Removed from local group"
    4756 = "Added to universal group"; 4757 = "Removed from universal group"
}

# Read each event's fields by name (not position), so every event type parses correctly
$events = Get-WinEvent -FilterHashtable @{ LogName = "Security"; Id = [int[]]$names.Keys; StartTime = $since } -ErrorAction SilentlyContinue |
    ForEach-Object {
        $d = @{}
        ([xml]$_.ToXml()).Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
        $target = if ($d.MemberName) { "$($d.MemberName -replace '^CN=([^,]+).*','$1') -> $($d.TargetUserName)" } else { $d.TargetUserName }
        [pscustomobject]@{ Time = $_.TimeCreated; EventID = $_.Id; Action = $names[$_.Id]; Target = $target; By = $d.SubjectUserName }
    }

$disabled = Search-ADAccount -AccountDisabled -UsersOnly | Get-ADUser -Properties Description |
    Select-Object Name, SamAccountName, Description, @{n = "Location"; e = { ($_.DistinguishedName -split ",", 2)[1] }}
$locked   = Search-ADAccount -LockedOut -UsersOnly | Select-Object Name, SamAccountName
# pwdLastSet = 0 means the temporary password has never been changed
$pending  = Get-ADUser -Filter 'Enabled -eq $true' -Properties pwdLastSet, whenCreated |
    Where-Object { $_.pwdLastSet -eq 0 } | Select-Object Name, SamAccountName, whenCreated
$inactive = Search-ADAccount -AccountInactive -TimeSpan (New-TimeSpan -Days $Days) -UsersOnly |
    Where-Object { $_.Enabled } | Select-Object Name, SamAccountName, LastLogonDate

function New-ReportSection($title, $data) {
    if ($data) { $data | ConvertTo-Html -Fragment -PreContent "<h2>$title ($(@($data).Count))</h2>" }
    else { "<h2>$title (0)</h2><p>None</p>" }
}

$css  = '<style>body{font-family:Segoe UI,Arial;margin:20px} h1{color:#1f4e79} h2{color:#2e75b6;border-bottom:1px solid #ccc} table{border-collapse:collapse;margin-bottom:20px} th,td{border:1px solid #ccc;padding:4px 8px;text-align:left} th{background:#e7eef7}</style>'
$body = @(
    "<h1>Account Audit - homelab.local</h1><p>Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm') by $env:USERNAME, covering the last $Days days</p>"
    New-ReportSection "Account changes from the Security log" ($events | Sort-Object Time -Descending)
    New-ReportSection "Disabled accounts" $disabled
    New-ReportSection "Currently locked out" $locked
    New-ReportSection "New accounts waiting for first sign-in" $pending
    New-ReportSection "Enabled accounts with no sign-in in $Days days" $inactive
)
$file = "$outDir/account-audit-$stamp.html"
ConvertTo-Html -Head $css -Title "Account Audit $stamp" -Body ($body | Out-String) | Set-Content $file

Write-Host "Account audit for the last $Days days" -ForegroundColor Cyan
Write-Host "  Account changes logged:      $(@($events).Count)"
Write-Host "  Disabled accounts:           $(@($disabled).Count)"
Write-Host "  Currently locked out:        $(@($locked).Count)"
Write-Host "  Waiting for first sign-in:   $(@($pending).Count)"
Write-Host "  Inactive enabled accounts:   $(@($inactive).Count)"
Write-Host "Report saved to $file" -ForegroundColor Yellow
