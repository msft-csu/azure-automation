# azure-automation
Azure Automation runbook examples

## copy-blobs.ps1
Use this script to copy files from one blob account to another.  You can use this script to move files that don't exist to a destination account.  This script does NOT keep accounts in sync.  It only copies files that don't exist in the destination.

## get-resources.ps1
This script simply prints out the resources that the service account has access to.  It's primary purpose is to demonstrate how to login using the RunAs service principal account
