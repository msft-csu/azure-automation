<#
Copyright (c) Microsoft Corporation. All rights reserved.
Licensed under the MIT License.
#>

<#
.SYNOPSIS
Update Azure PowerShell modules in an Azure Automation account.

.DESCRIPTION
This Azure Automation runbook logins into Azure

Prerequisite: an Azure Automation account with an Azure Run As account credential.

.PARAMETER AutomationAccountName
The Azure Automation account name.

.PARAMETER AzureEnvironment
(Optional) Azure environment name.

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
param(

    [string] $AutomationAccountName = 'AzureRunAsConnection',
    [string] $AzureEnvironment = 'AzureUSGovernment'
)


# Use the Run As connection to login to Azure
function Login-AzureAutomation {
    try {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $AutomationAccountName     

        "Logging in to Azure..."
        Login-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
            -EnvironmentName $AzureEnvironment

        Select-AzureRmSubscription -SubscriptionId $servicePrincipalConnection.SubscriptionID  | Write-Verbose
    } catch {
        if (!$RunAsConnection) {
            Write-Output $servicePrincipalConnection
            Write-Output $_.Exception
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        }

        throw $_.Exception
    }
}


Login-AzureAutomation


#Get all ARM resources from all resource groups
$ResourceGroups = Get-AzureRmResourceGroup 

foreach ($ResourceGroup in $ResourceGroups)
{    
    Write-Output ("Showing resources in resource group " + $ResourceGroup.ResourceGroupName)
    $Resources = Get-AzureRmResource -ResourceGroupName $ResourceGroup.ResourceGroupName | Select ResourceName, ResourceType
    ForEach ($Resource in $Resources)
    {
        Write-Output ($Resource.ResourceName + " of type " +  $Resource.ResourceType)
    }
    Write-Output ("")
} 

