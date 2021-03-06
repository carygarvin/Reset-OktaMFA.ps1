# Reset-OktaMFA.ps1
PowerShell Script to reset Okta MFAs for users with last used MFAs older than a certain age or never used.

Author       : Cary GARVIN  
Contact      : cary(at)garvin.tech  
LinkedIn     : [https://www.linkedin.com/in/cary-garvin](https://www.linkedin.com/in/cary-garvin)  
GitHub       : [https://github.com/carygarvin/](https://github.com/carygarvin/)  


Script Name  : [Reset-OktaMFA.ps1](https://github.com/carygarvin/Reset-OktaMFA.ps1/)  
Script Link  : https://carygarvin.github.io/Reset-OktaMFA.ps1/  
Version      : 1.0  
Release date : 26/11/2018 (CET)  

# Script usage
Script takes either none or one argument when launched.  
* No argument will trigger the script in simulation mode.  
* `ResetFromUsageReport` argument will trigger the Script so that Okta MFA resets are performed based on input from the chosen CSV file (after entry dedup and date filtering).  
* Any other combination of arguments will cause the Script to abort displaying info with possible options for the Script.  


This Script will first list CSV files stored in the current user's '_Downloads_' folder. Prior to that, the user needs to download from the Okta Admin portal (Admin>Reports>Reports>Multifactor Authentication>MFA Usage/Download CSV) the latest MFA Usage report which serves as input for the present script.
Upon launching the script, the user will be prompted to choose the CSV file with last MFA usage information. The Script will then parse the CSV file and keep only unique entries with the most recent 'Last Used MFA' for each user. Then it filters out entries which are more recent than the specified number of days in variable **$MFAResetThresholdAge**.
From the remaining entries (older than age threshold or blank), it will reset the MFA for each one and finally output in the current user's '_My Documents_' folder the result in a CSV file titled with the execution time stamp followed by "__MFAResetReport.csv__".

# Script configuration
There are 3 configurable variables (see lines 91 to 94 within the script) which need to be set by IT Administrator prior to using the present Script:  
* Variable **$OktaOrgName** which is the name, in the Okta Portal URL, corresponding to your organization.  
* Variable **$OktaAPIToken** which is the temporary token Okta issued for you upon request. This token can be issued and taken from Admin>Security>API>Token once you are logged in the Okta Admin Portal.  
* Variable **$MFAResetThresholdAge** which is the chosen last used MFA age in days beyond which the MFA reset is performed. Obviously for those that have never connected (blank last used date), the MFA will also be reset.  
