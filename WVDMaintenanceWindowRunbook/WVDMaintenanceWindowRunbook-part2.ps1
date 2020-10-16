# Select run-as account

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

# Re-enable the Auto-Scaling Logic App 
Write-Output "Re-enabling WVD Auto-Scaling... "
Set-AzureRMLogicApp -ResourceGroupName $AutomationResourceGroup -Name $LogicAppName -state Enabled -force