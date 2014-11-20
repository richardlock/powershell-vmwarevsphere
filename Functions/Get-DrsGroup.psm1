Function Get-DrsGroup {
<#
.SYNOPSIS
Retrieves DRS groups from a cluster.

.DESCRIPTION
Retrieves DRS groups from a cluster.

.PARAMETER Cluster
Specify the cluster for which you want to retrieve the DRS groups

.PARAMETER Name
Specify the name of the DRS group you want to retrieve.

.PARAMETER Type
Specify the type of DRS group (ClusterVmGroup/ClusterHostGroup).

.EXAMPLE
Get-DrsGroup -Cluster "Cluster" -Name "VM DRS Group"
Retrieves the DRS group "VM DRS Group" from cluster "Cluster".

.EXAMPLE
Get-DrsGroup -Cluster "Cluster" -Name "VM DRS Group" -Type ClusterVmGroup
Retrieves the DRS group "VM DRS Group" of Type "ClusterVmGroup" from cluster "Cluster".

.EXAMPLE
Get-Cluster | Get-DrsGroup
Retrieves all the DRS groups for all clusters.

.INPUTS
ClusterImpl

.OUTPUTS
ClusterVmGroup
ClusterHostGroup

.COMPONENT
VMware vSphere PowerCLI
#>

  [CmdletBinding()]

  Param([parameter(Mandatory=$true, ValueFromPipeline=$true)]$Cluster,
        [string] $Name="*",
        [string] $Type)

  Process {
    $Cluster = Get-Cluster -Name $Cluster
    If ($Cluster) {
      If (-not $Type) {
        $Cluster.ExtensionData.ConfigurationEx.Group | Where {$_.Name -like $Name}
      }
      ElseIf ($Type -and (($Type -ne "ClusterVmGroup") -and ($Type -ne "ClusterHostGroup"))) {
        Write-Error "The DRS Group Type paramater must be either ""ClusterVmGroup"" or ""ClusterHostGroup""."
      }
      Else {
        $Cluster.ExtensionData.ConfigurationEx.Group | Where {($_.Name -like $Name) -and ($_.GetType().Name -eq $Type)}
      }
    }
  }
}