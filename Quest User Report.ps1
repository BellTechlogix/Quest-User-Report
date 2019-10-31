<#
	QADUserReport.ps1
	Created By - Kristopher Roy
	Created On - May 2017
	Modified On - 31 Oct 2019

	This Script Requires that the Quest_ActiveRolesManagementShellforActiveDirectory be installed https://www.powershelladmin.com/wiki/Quest_ActiveRoles_Management_Shell_Download
	Pulls a report of all Active Directory User accounts
#>

add-pssnapin quest.activeroles.admanagement
Import-Module activedirectory

#Organization that the report is for
$org = "MyCompany"

#modify this for your searchroot can be as broad or as narrow as you need down to OU
$domainRoot = "dc=mydomain,dc=com"

#folder to store completed reports
$rptfolder = "c:\reports\"

#mail recipients for sending report
$recipients = @("BTL SCCM <sccm@belltechlogix.com>","BTL ITAMS <ITAM@belltechlogix.com>")

#from address
$from = "ADReports@wherever.com"

#smtpserver
$smtp = "mail.wherever.com"

#Timestamp
$runtime = Get-Date -Format "yyyyMMMdd"

#deffinition for UAC codes
$lookup = @{4096="Workstation/Server"; 4098="Disabled Workstation/Server"; 4128="Workstation/Server No PWD"; 
4130="Disabled Workstation/Server No PWD"; 528384="Workstation/Server Trusted for Delegation";
528416="Workstation/Server Trusted for Delegation"; 532480="Domain Controller"; 66176="Workstation/Server PWD not Expire"; 
66178="Disabled Workstation/Server PWD not Expire";512="User Account";514="Disabled User Account";66048="User Account PWD Not Expire";66050="Disabled User Account PWD Not Expire"}

$qadusers = get-qaduser -searchroot $domainRoot -searchscope subtree -sizelimit 0 -includedproperties displayname,SamAccountName,givenName,sn,UserPrincipalName,memberof,telephoneNumber,mobile,mail,userAccountControl,whenCreated,whenChanged,lastlogondate,dayssincelogon,lastlogontimestamp,employeetype,description,office,City,cn,badPasswordTime,pwdLastSet,LockedOut,accountExpires,ProxyAddresses|Select-Object -Property displayname,SamAccountName,givenName,sn,UserPrincipalName,lastlogontimestamp,@{N='dayssincelogon';E={(new-timespan -start (get-date $_.LastLogonTimestamp -Hour "00" -Minute "00") -End (get-date -Hour "00" -Minute "00")).Days}},employeetype,@{N='userAccountControl';E={$lookup[$_.userAccountControl]}},@{N='Groups';E={[system.String]::Join(", ", ($_.memberof|get-adgroup|select name -expandproperty name))}},telephoneNumber,mobile,mail,whenCreated,whenChanged,description,office,City,badPasswordTime,pwdLastSet,LockedOut,accountExpires,@{N='ProxyAddresses';E={[system.String]::Join(", ", ($_.ProxyAddresses))}}|sort sn

$qadusers|export-csv $rptFolder$runtime-qADUserReport.csv -NoTypeInformation

$usercount = $qadusers.Count

$emailBody = "<h1>$org Weekly ADUser Report</h1>"
$emailBody = $emailBody + "<h2>$org ADUser Count - '$usercount'</h2>"
$emailBody = $emailBody + "<p><em>"+(Get-Date -Format 'MMM dd yyyy HH:mm')+"</em></p>"

$htmlforEmail = $emailBody + @'
<h3>Included Fields:</h3>
<table style="height: 535px;" border="1" width="625">
<tbody>
<tr>
<td style="width: 304px;"><strong>displayname</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>SamAccountName</strong></td>
<td style="width: 305px;"><em>System Name used by Active Directory</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>givenName</strong></td>
<td style="width: 305px;"><em>First Name</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>sn</strong></td>
<td style="width: 305px;"><em>Last Name</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>UserPrincipalName</strong></td>
<td style="width: 305px;"><em>System Name used by multiple platforms</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>lastlogontimestamp</strong></td>
<td style="width: 305px;"><em>if available, last time AD recorded login</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>dayssincelogon</strong></td>
<td style="width: 305px;"><em>calculated from lastlogontimestamp</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>employeetype</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>userAccountControl</strong></td>
<td style="width: 305px;"><em>User settings for AD</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>Groups</strong></td>
<td style="width: 305px;"><em>AD Groups user is member of</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>telephoneNumber</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>mobile</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>mail</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>whenCreated</strong></td>
<td style="width: 305px;"><em>When account was created</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>whenChanged</strong></td>
<td style="width: 305px;"><em>Date AD changes were made to account</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>description</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>office</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>City</strong></td>
<td style="width: 305px;">&nbsp;</td>
</tr>
<tr>
<td style="width: 304px;"><strong>badPasswordTime</strong></td>
<td style="width: 305px;"><em>Last time password was typed incorrectly</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>pwdLastSet</strong></td>
<td style="width: 305px;"><em>Last time password was reset</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>LockedOut</strong></td>
<td style="width: 305px;"><em>account lockout details</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>accountExpires</strong></td>
<td style="width: 305px;"><em>Date Account expires if set</em></td>
</tr>
<tr>
<td style="width: 304px;"><strong>ProxyAddresses</strong></td>
<td style="width: 305px;"><em>email addresses for account</em></td>
</tr>
</tbody>
</table>
'@

Send-MailMessage -from $from -to $recipients -subject "$org - AD User Report" -smtpserver $smtp -BodyAsHtml $htmlforEmail -Attachments $rptFolder$runtime-qADUserReport.csv
