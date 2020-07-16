# ***************************************************************************************************
# ***************************************************************************************************
#
#  Author       : Cary GARVIN
#  Contact      : cary(at)garvin.tech
#  LinkedIn     : https://www.linkedin.com/in/cary-garvin
#  GitHub       : https://github.com/carygarvin/
#
#
#  Script Name  : Reset-OktaMFA.ps1
#  Version      : 1.0
#  Release date : 26/11/2018 (CET)
#
#
#  Script takes either no or one argument when launched.
#       - No argument will trigger the script in simuation mode.
#       - 'ResetFromUsageReport' argument will trigger the script so that Okta MFA resets are performed based on input from the chosen CSV file (after entry dedup and date filtering).
#       - Any other combination of arguments will cause the script to abort displaying info on possible options for the script.
#
#
#  This script will first list CSV files stored in the current user's 'Downloads' folder. Prior to that, the user needs to download from the Okta Admin portal
#  (Admin/Reports/Reports/Multifactor Authentication/MFA Usage/Download CSV) the latest MFA Usage report which serves as input for the present script.
#  Upon launching the script the user will be prompted to chose the CSV file with last MFA usage information.
#  The Script will then parse the CSV file and keep only unique entries with the most recent 'Last Used MFA' for each user. Then it filters out entries which are more recent than the specified number of days in variable $MFAResetThresholdAge.
#  From the entries left (older than age treshold or blank), it will reset the MFA for each one of them and finally output in the current users 'My Documents' folder the result in a CSV file titled with the execution time stamp followed by "_MFAResetReport.csv".
#
#  There are 3 configurable variables (see lines 29 and 30 below) which need to be set by IT Administrator prior to using the present Script:
#  Variable '$OktaOrgName' which is the name, in the Okta Portal URL, corresponding to your organization.
#  Variable '$OktaAPItoken' which is the temporary token Okta issued for you upon request. This token can be issued and taken from Admin>Security>API>Token once your are logged in the Okta Admin Portal.
#  Variable '$MFAResetThresholdAge' which is the chosen last used MFA age in days beyond which the MFA reset is performed. Obviously for those that have never connected (blank last used date), the MFA will also be reset.
#     
#
# ***************************************************************************************************
# ***************************************************************************************************




$error.Clear()




####################################################################################################
#                                 Handling of Script parameters                                    #
# Launched with no parameter, the script will simulate its operation thus making no actual resets  #
# Launched with 'ResetFromUsageReportIt' (the scipt will actually perform reset actions as instructed)       #
####################################################################################################



If (($args.length -eq 1) -and ($args[0] -eq "ResetFromUsageReport"))
	{
	write-host "You have invoked the script in order to reset the Multifactor Authentication settings for users which either never connected to Okta or with usage older than the value specified in `$MFAResetThresholdAge." -foregroundcolor "gray"
	If ((read-host "r`nAre you sure you want to reset MFA from information in the CSV file you will choose ?") -eq "Y")
		{
		write-host "MFA reset will be performed for all matching logons in the CSV file!" -foregroundcolor "gray"
		start-sleep -s 5
		$ScriptMode = "ResetFromUsageReport"
		}
	Else
		{
		write-host "Script Execution not confirmed. Aborting script!" -foregroundcolor "gray"
		Break
		}
	}
ElseIf ($args.length -eq 0)
	{
	write-host "Running script in simulation mode" -foregroundcolor "gray"
	$ScriptMode = "SimulateResets"
	}
Else
	{
	write-host "Unsupported arguments specified. Aborting script!" -foregroundcolor "gray"
	write-host "`r`nSupported arguments are as follows:" -foregroundcolor "gray"
	write-host "`tNo argument for script execution is simulation mode (WhatIf)" -foregroundcolor "gray"
	write-host "`tArgument 'ResetFromUsageReport' in order to reset the MFA to default choice for all users with old or no usage date." -foregroundcolor "gray"
	Break
	}




####################################################################################################
#                               Admin User configurable parameters                                 #
# $MFAResetThresholdAge is the age in days of last MFA usage beyond which resets will be performed #
# $OktaAPItoken is the Okta Security Token downloaded (Admin/Security/API/Tokens) from the Okta    #
# portal for the Admin user currently running the present gorgeous script                          #
####################################################################################################

$OktaOrgName = "contoso"                                             # Your Okta Organization name
$OktaAPItoken = "GoAndGenerateYourTokenThenCopyItAndPasteItHere"     # Temporary token generated from Okta Portal (Admin/Security/API/Tokens)

$MFAResetThresholdAge = 365                                          # Age value in days for which Okta MFA resets need to be performed




####################################################################################################
#                                          Script Main                                             #
####################################################################################################


$script:ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$script:ScriptName = (Get-Item $MyInvocation.MyCommand).basename
$script:ExecutionTimeStamp = get-date -format "yyyy-MM-dd_HH-mm-ss"
$script:ScriptLaunch = get-date -format "yyyy/MM/dd HH:mm:ss"
$script:MyDocsFolder = [Environment]::GetFolderPath("MyDocuments")


Start-Transcript -Path "$($script:ScriptPath)\$($script:ExecutionTimeStamp)_$($script:ScriptName).log" -NoClobber | out-null

$OlderThanDate = (Get-Date).AddDays(-$MFAResetThresholdAge)
$CSVFilesDir = $env:userprofile + "\Downloads"
$ExpectedCSVHeader = @('User','Login','MFA Factor','Last Enrolled','Last Enrolled_ISO8601','Last Used','Last Used_ISO8601')


write-host "`r`nList of CSV files found in Downloads '$CSVFilesDir' directory:`r`n" -foregroundcolor "white"
$CSVFiles = Get-ChildItem -Path $CSVFilesDir | Where-Object {$_.Extension -like ".csv"}
For ($i=0; $i-le $CSVFiles.length-1; $i++) {"`tCSV file #{0} ->`t'{1}'`t[Last modified: {2}]" -f $($i+1),$CSVFiles[$i],$CSVFiles[$i].LastWriteTime}

$CSVFileNrToOpen = read-host -Prompt "`r`nSpecify the number of the MFA Usage Report CSV file."
$OktaMFAUsageReportCSV =  $($CSVFiles[$CSVFileNrToOpen-1])


$MFAUsageReport =  import-csv -Delimiter "," -Path ($CSVFilesDir + "\" + $OktaMFAUsageReportCSV)
$SelectedCSVHeader = ($MFAUsageReport | Get-Member -MemberType NoteProperty).Name


If (Compare-Object -ReferenceObject $ExpectedCSVHeader -DifferenceObject $SelectedCSVHeader)
	{
	write-host "CSV file '$CSVFilesDir\$OktaMFAUsageReportCSV' is not a valid MFA Usage Report!" -foregroundcolor "red"
	write-host "`r`nIts headers are as follows:"
	$SelectedCSVHeader
	write-host "`r`nWhile the expected headers for a proper MFA Usage Report CSV file are as follows:"
	$ExpectedCSVHeader
	}
Else 
	{
	write-host "Selected raw MFA Usage report contains $($MFAUsageReport.length) entries"
	
	$FilteredMFAUsage = $MFAUsageReport | Group User | Foreach {$_.Group | Sort "Last Used_ISO8601" -Descending | Select -First 1}
	write-host "There are only $($FilteredMFAUsage.length) unique entries to process."
	$FilteredMFAUsage = $FilteredMFAUsage | Foreach-Object {If ($_."Last Used_ISO8601" -eq "") {$_."Last Used_ISO8601" = "1900-01-01T00:00:00.000Z";$_} Else {$_}}
	$OverAgeThresholMFAUsage = $FilteredMFAUsage | Where-Object {([DateTime]::ParseExact($_."Last Used_ISO8601", 'yyyy-MM-ddTHH:mm:ss.000Z', [Globalization.CultureInfo]::InvariantCulture)) -lt $OlderThanDate }
	$OverAgeThresholMFAUsage = $OverAgeThresholMFAUsage | Foreach-Object {If ($_."Last Used_ISO8601" -eq "1900-01-01T00:00:00.000Z") {$_."Last Used_ISO8601" = ""; $_} Else {$_}}
	write-host "There are only $($OverAgeThresholMFAUsage.length) with MFA last used date older than configured $MFAResetThresholdAge days."
	start-sleep -s 2

	$MFAResetReport = @()
	$i = 1
	$SuccessfulResets = 0
	$FailedResets = 0
	ForEach ($OktaUser in $OverAgeThresholMFAUsage) {
		$OktaUserToReset  = $OktaUser.Login
		write-host "Processing filtered entry #$i '$OktaUserToReset'".PadRight(75,' ') -NoNewLine
		write-host "`t-->`t" -NoNewLine
		If ($ScriptMode -eq "ResetFromUsageReport")
			{
			$uri = "https://$OktaOrgName.okta-emea.com/api/v1/users/" + $OktaUserToReset + "/lifecycle/reset_factors"
			Try
				{
				$webResponse = Invoke-WebRequest -Uri $uri -Headers @{Authorization = "SSWS "+$OktaAPItoken} -Method POST
				# $webResponse.StatusCode # Returns code '200' if OK
				If ($webResponse.StatusDescription -eq "OK")
					{
					write-host "Okta MFA reset successful!" -foregroundcolor "green"
					$MFAResetReport += $OktaUser | Select-Object *, @{l="ResetMFAStatus"; e={"Success"}}
					$SuccessfulResets++
					}
				}
			Catch
				{
				write-host "Okta MFA reset failed!" -foregroundcolor "red"
				$MFAResetReport += $OktaUser | Select-Object *, @{l="ResetMFAStatus"; e={"Failed"}}
				$FailedResets++
				}
			}
		Else
			{
			write-host "Okta MFA reset not performed!" -foregroundcolor "cyan"
			$MFAResetReport += $OktaUser | Select-Object *, @{l="ResetMFAStatus"; e={"N/A"}}
			}
		$i++
		}
	$MFAResetReport | export-csv "$($script:MyDocsFolder)\$($script:ExecutionTimeStamp)_MFAResetReport.csv" -NoTypeInformation
	}


write-host "`r`nScript gracefully ended!"
write-host "A total of $SuccessfulResets/$i Okta MFA resets were successful."
write-host "A total of $FailedResets/$i Okta MFA resets failed."

	
Stop-Transcript | out-null
If ($error) {$error | out-file "$($script:ScriptPath)\$($script:ExecutionTimeStamp)_$($script:ScriptName)_errors.log"}
$error.clear()