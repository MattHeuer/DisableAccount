<#
.SYNOPSIS
    Used to disable accounts, strip all memberships and move to the appropriate OU.
.DESCRIPTION
    This script is designed to disable an account, remove all groups and move the account to the disabled users OU. An extract will be created containing the users groups and general account info at the time of disablement.
.NOTES
    Generated On: 24/12/2020
    Updated On: 07/04/2020
    Author: Matthew Heuer
#>
Import-Module ActiveDirectory

$SAM = Read-Host "Enter the sAMAccountname of the terminated user"
$USER = Get-ADUser -Identity $SAM
    if ($USER) {
          Write-Host "Found user $USER with username: $SAM" -ErrorAction Stop
     } else {
          Write-Warning "No user in AD found using the username: $SAM"
          Exit
     }
$RITM= Read-Host "Enter the RITM number of the ticket"
$Admin = $env:UserName
$Today = Get-Date -Format "dd/MM/yyyy"
$Date = Get-Date -Format FileDate
$Notes = "Disabled $Today $RITM $Admin"
$ContextServer = Get-ADDomain | Select-Object -ExpandProperty forest

if ($ContextServer -eq 'dhw.wa.gov.au') {
    $InfoPath = # Insert Info export path here as a TXT file #
    $MemberPath = # Insert Membership export path here as a CSV file #
} else {
    $InfoPath = "C:\temp\MHeuer\Exports\$RITM-$SAM-UserInfo-$Date.txt"
    $MemberPath = "C:\temp\MHeuer\Exports\$RITM-$SAM-GroupMembership-$Date.csv"
}

Get-ADUser $User | Select-Object -Property DistinguishedName,GivenName,Name,ObjectGUID,SamAccountName,SID,UserPrincipalName | Out-File -FilePath $InfoPath -NoClobber -Force

Get-ADPrincipalGroupMembership $USER -ResourceContextServer $ContextServer | Export-Csv -Path $MemberPath -NoTypeInformation
Get-ADUser -Identity $USER -Properties MemberOf | ForEach-Object {
    $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
}

if ($INFO = (Get-ADUser -Identity $USER -Properties info).info) {
    Set-ADUser -Identity $USER -Replace @{info="$INFO`r`n$Notes;"}
} else {
    Set-ADUser -Identity $USER -Replace @{info="$Notes;"}
}

Disable-ADAccount -Identity $USER
$GUID = Get-ADUser -Identity $USER | Select-Object -ExpandProperty ObjectGUID
if ($ContextServer -eq 'dhw.wa.gov.au') {
    Move-ADObject -Identity $GUID -TargetPath "OU=Disabled_Users,DC=dhw,DC=wa,DC=gov,DC=au"
} elseif ($ContextServer -eq 'ad.dcd.wa.gov.au') {
    Move-ADObject -Identity $GUID -TargetPath 'OU=Disabled Users,OU=Core Infrastructure,DC=ad,DC=dcd,DC=wa,DC=gov,DC=au'
} elseif ($ContextServer -eq 'PreProd.com.au') {
    Move-ADObject -Identity $GUID -TargetPath 'OU=DisabledUsers,DC=PreProd,DC=com,DC=au'
} elseif ($ContextServer -eq 'test.dcd.wa.gov.au') {
    Move-ADObject -Identity $GUID -TargetPath 'OU=Disabled Users,OU=Core Infrastructure,DC=TEST,DC=DCD,DC=WA,DC=GOV,DC=AU'
} elseif ($ContextServer -eq 'dsc.wa.gov.au') {
    Move-ADObject -Identity $GUID -TargetPath 'OU=Disabled Accounts,OU=Inactive Accounts,DC=dsc,DC=wa,DC=gov,DC=au'
} elseif ($ContextServer -eq 'dcptrn.local') {
    Continue
} else {
    Write-Host "Domain not recognised" -ForegroundColor Red -ErrorAction Stop
}

Write-Host "$SAM has been successfully disabled" -ForegroundColor Green
