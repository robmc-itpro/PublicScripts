$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
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

$AutomationResourceGroup = 'WVD-UK-Automation'
$LogicAppName = 'WVD-UK-HP001_Autoscale_Scheduler'
$AutomationAccountName = 'WVD-UK-AutomationAccount'
$RunbookName = 'WVDAutoStartRunbook'
$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID
$params = @{"AzureResourceGroup"="WVD-UK"}
$WaitSeconds = 14400

# Disable the Auto-Scaling Logic App
Write-Output "Disabling WVD Auto-Scaling... "
Set-AzureRMLogicApp -ResourceGroupName $AutomationResourceGroup -Name $LogicAppName -state Disabled -force

# Start All WVD Hosts
Write-Output "Running '$($RunBookName)'... "
Start-AzureRMAutomationRunbook `
    –AutomationAccountName $AutomationAccountName `
    –Name $RunBookName `
    -ResourceGroupName $AutomationResourceGroup `
    -DefaultProfile $AzureContext `
    –Parameters $params –Wait

# Go to sleep
Write-Output "Sleeping for '$($WaitSeconds)' seconds... "
start-sleep -seconds $WaitSeconds 

# Re-enable the Auto-Scaling Logic App 
Write-Output "Re-enabling WVD Auto-Scaling... "
Set-AzureRMLogicApp -ResourceGroupName $AutomationResourceGroup -Name $LogicAppName -state Enabled -force