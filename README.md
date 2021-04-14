# DisableAccount.ps1
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
