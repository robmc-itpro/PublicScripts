Param
(   
	[Parameter(Mandatory=$true)]
	[String]
	$AzureResourceGroup
)

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


Write-Output "Starting VMs in '$($AzureResourceGroup)' resource group";


#ARM VMs

# Find VMs with the tag "WVDAutoStart"

$FoundVMs = Get-AzureRmResource -ResourceGroupName $AzureResourceGroup -TagName "WVDAutoStart"
"Found the following tagged VMs:"

$FoundVMs.name

#For each VM, find their current power status
#If VM is in the stopped or deallocated state, power it on
$FoundVMs | ForEach-Object {

	$vmStatus = Get-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name -Status
	$vmState = $vmstatus.Statuses[1].Code.Split('/')[1]
	Write-Output "The current power state of '$($vmStatus.name)' is '$($vmState)'";	
	
	if ($vmState -eq 'stopped' -or $vmState -eq 'deallocated') {
		Write-Output "Starting '$($_.Name)' ...";			
		Start-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name -ErrorAction Continue;	
		}		
		
};