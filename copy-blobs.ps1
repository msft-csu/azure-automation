<#
    .DESCRIPTION
        An example runbook which gets all the Classic VMs in a subscription using the Classic Run As Account (certificate)
		and then outputs the VM name and status

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: 2016-6-1
#>

<#
.SYNOPSIS
Update Azure PowerShell modules in an Azure Automation account.

.DESCRIPTION
This Azure Automation runbook logins into Azure and copies blobs from one storage account to another

Prerequisite: an Azure Automation account with an Azure Run As account credential.

.PARAMETER AutomationAccountName
The Azure Automation account name.

.PARAMETER AzureEnvironment
(Optional) Azure environment name.

.PARAMETER Storage_Endpoint
(Optional) Storage Endpoint of Azure cloud

.PARAMETER Source_Storage_Acct
.PARAMETER Source_Blob_Container
.PARAMETER Source_Account_Key

.PARAMETER Dest_Storage_Acct
.PARAMETER Dest_Blob_Container
.PARAMETER Dest_Account_Key

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
param(

    [string] $AutomationAccountName = 'AzureRunAsConnection',
    [string] $AzureEnvironment = 'AzureUSGovernment',
    [string] $Storage_Endpoint = 'core.usgovcloudapi.net',
    [Parameter (Mandatory= $true)][string] $Source_Storage_Account,
    [Parameter (Mandatory= $true)][string] $Dest_Storage_Account,
    [Parameter (Mandatory= $true)][string] $Source_Blob_Container,
    [Parameter (Mandatory= $true)][string] $Dest_Blob_Container,
    [Parameter (Mandatory= $true)][string] $Source_Account_Key,
    [Parameter (Mandatory= $true)][string] $Dest_Account_Key

)

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $AutomationAccountName     


    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
        -EnvironmentName $AzureEnvironment
 }
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Log Copy Starts Here

$SourceStorageContext = New-AzureStorageContext -StorageAccountName $Source_Storage_Account -StorageAccountKey $Source_Account_Key -Endpoint $Storage_Endpoint
$DestStorageContext = New-AzureStorageContext -StorageAccountName $Dest_Storage_Account -StorageAccountKey $Dest_Account_Key -Endpoint $Storage_Endpoint

$Containers = Get-AzureStorageContainer -Context $SourceStorageContext -Name $Source_Blob_Container

foreach($Container in $Containers)
{
    $ContainerName = $Container.Name
    if (!((Get-AzureStorageContainer -Context $DestStorageContext) | Where-Object { $_.Name -eq $Dest_Blob_Container }))
    {   
        Write-Output "Creating new container $ContainerName"
        New-AzureStorageContainer -Name $ContainerName -Permission Off -Context $DestStorageContext -ErrorAction Stop
    }

    $Blobs = Get-AzureStorageBlob -Context $SourceStorageContext -Container $ContainerName
    $BlobCpyAry = @() #Create array of objects

    #Do the copy of everything
    foreach ($Blob in $Blobs)
    {
        $BlobName = $Blob.Name
        $blob = Get-AzureStorageBlob -Blob $BlobName -Container $Dest_Blob_Container -Context $DestStorageContext -ErrorAction Ignore 
        if (-not $blob)
        {
            Write-Output "Copying $BlobName from $ContainerName"
            $BlobCopy = Start-CopyAzureStorageBlob -Context $SourceStorageContext -SrcContainer $ContainerName -SrcBlob $BlobName -DestContext $DestStorageContext -DestContainer $Dest_Blob_Container -DestBlob $BlobName
            $BlobCpyAry += $BlobCopy
        }  
    } 
    #Check Status
    foreach ($BlobCopy in $BlobCpyAry)
    {
       #Could ignore all rest and just run $BlobCopy | Get-AzureStorageBlobCopyState but I prefer output with % copied
       $CopyState = $BlobCopy | Get-AzureStorageBlobCopyState
       $Message = $CopyState.Source.AbsolutePath + " " + $CopyState.Status + " {0:N2}%" -f (($CopyState.BytesCopied/$CopyState.TotalBytes)*100) 
       Write-Output $Message
    }
}