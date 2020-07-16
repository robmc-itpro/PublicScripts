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
$AzureContext = Get-AzSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID
$params = @{"AzureResourceGroup"="WVD-UK"}

# Disable the Auto-Scaling Logic App
Write-Out "Disabling WVD Auto-Scaling... "
Set-AzureRMLogicApp -ResourceGroupName $AutomationResourceGroup -Name $LogicAppName -state Disabled

# Start All WVD Hosts

Start-AzAutomationRunbook `
    –AutomationAccountName $AutomationAccountName `
    –Name $RunBookName `
    -ResourceGroupName $AutomationResourceGroup `
    -AzContext $AzureContext `
    –Parameters $params –Wait

# Wait for 4 Hours
Write-Out "Sleeping for 4 hours... "
start-sleep 14400 -seconds

# Re-enable the Auto-Scaling Logic App 
Write-Out "Re-enabling WVD Auto-Scaling... "
Set-AzureRMLogicApp -ResourceGroupName $AutomationResourceGroup -Name $LogicAppName -state Enabled