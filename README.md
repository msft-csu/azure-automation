# azure-automation
Azure Automation runbook examples.  These scripts default to running in the AzureUSGovernment cloud but can be changed via prompts when you run the script to run in AzureCloud.  

> You will need to ensure that you have updated the modules in your automation account to at least Azure 5.3.0 (circa  6/5/2019).  Earlier versions of the modules in GOV did not work correctly and produced a "Confidential Client is not supported in Cross Cloud request" error

## copy-blobs.ps1
Use this script to copy files from one blob account to another.  You can use this script to move files that don't exist to a destination account.  This script does NOT keep accounts in sync.  It only copies files that don't exist in the destination.

## get-resources.ps1
This script simply prints out the resources that the service account has access to.  It's primary purpose is to demonstrate how to login using the RunAs service principal account
