Function Update-ClusterVMDrsGroups {
<#
.SYNOPSIS
Updates cluster VM DRS groups for MetroCluster site affinity.

.DESCRIPTION
Updates cluster VM DRS groups for MetroCluster site affinity.

.PARAMETER Cluster
Specify the cluster for which you want to update the VM DRS groups.

.PARAMETER SiteADatastore
Specify the string to match for site A datastores.

.PARAMETER SiteBDatastore
Specify the string to match for site B datastores.

.PARAMETER SiteADrsGroup
Specify the string to match for site A VM DRS Group.

.PARAMETER SiteBDrsGroup
Specify the string to match for site B VM DRS Group.

.EXAMPLE
Update-ClusterVMDrsGroups -Cluster "Cluster"
Updates VM DRS Groups of cluster "Cluster".

.EXAMPLE
Get-Cluster "Cluster" | Update-ClusterVMDrsGroups
Updates VM DRS Groups of cluster "Cluster".

.INPUTS
ClusterImpl

.OUTPUTS
Task

.COMPONENT
VMware vSphere PowerCLI

.NOTES
  Version: 1.0 - Initial version
  Date: 2014-08-06
  Author: Richard Lock
  Tag: cluster,drs,group,metrocluster,site
#>

  [CmdletBinding (
    SupportsShouldProcess=$true
  )]

  Param (
    [parameter(Mandatory=$true, ValueFromPipeline=$true)] $Cluster,
    [string] $SiteADatastore = "kr*",
    [string] $SiteBDatastore = "ms*",
    [string] $SiteADrsGroup = "kr*",
    [string] $SiteBDrsGroup = "ms*"
  )

  Begin {
    # Array to hold VMs using datastores at both sites.
    $arrVMsAtBothSites = @()
  }
  
  Process {
    $Cluster | ForEach { 
	  $objCluster = Get-Cluster -Name $_
      If ($objCluster) {
        # Arrays to hold VMs added and removed from site A and B VM DRS Groups.
        $arrSiteARemoved = @()
        $arrSiteAAdded = @()
        $arrSiteBRemoved = @()
        $arrSiteBAdded = @()
            
        # Get all VMs in cluster on datastores at site A and B.
        $objSiteAVMs = Get-VM -Location $objCluster | Where {($_.DrsAutomationLevel -ne "Disabled") -and (($_.ExtensionData.Config.DatastoreUrl | ForEach {$_.Name}) -like $SiteADatastore)}
        $objSiteBVMs = Get-VM -Location $objCluster | Where {($_.DrsAutomationLevel -ne "Disabled") -and (($_.ExtensionData.Config.DatastoreUrl | ForEach {$_.Name}) -like $SiteBDatastore)}

        # Get cluster VM DRS Groups for site A and B.
        $objSiteADrsGroup = Get-DrsGroup -Cluster $objCluster -Name $SiteADrsGroup -Type "ClusterVmGroup"
        $objSiteBDrsGroup = Get-DrsGroup -Cluster $objCluster -Name $SiteBDrsGroup -Type "ClusterVmGroup"

        # Check VMs in site A.
        Write-Verbose "Checking VMs in site ""$SiteADrsGroup""..."
        $objSiteAVMs | ForEach {
          # If site A VM is also in site B VM array, add to array of VMs using datastores at both sites.
          If ($objSiteBVMs -contains $_) {
            If ($arrVMsAtBothSites -notcontains $_) {
              $arrVMsAtBothSites += $_
            }
          }
          Else {
            # If site A VM is in site B VM DRS Group, remove from site B VM DRS Group.
            If ($objSiteBDrsGroup.Vm -contains $_.ExtensionData.MoRef) {
              If ($PSCmdlet.ShouldProcess($_)) {
                Remove-VMFromDrsGroup -Cluster $objCluster -DrsGroup $objSiteBDrsGroup -VM $_
              }
              $arrSiteBRemoved += $_
            }
            # If site A VM is not in site A VM DRS Group, add to site A VM DRS Group.
            If ($objSiteADrsGroup.Vm -notcontains $_.ExtensionData.MoRef) {
              If ($PSCmdlet.ShouldProcess($_)) {
                Add-VMToDrsGroup -Cluster $objCluster -DrsGroup $objSiteADrsGroup -VM $_
              }
              $arrSiteAAdded += $_
            }
          } 
        }

        # Check VMs in site B.
        Write-Verbose "Checking VMs in site ""$SiteBDrsGroup""..."
        $objSiteBVMs | ForEach {
          # If site B VM is also in site A VM array, add to array of VMs using datastores at both sites.
          If ($objSiteAVMs -contains $_) {
            If ($arrVMsAtBothSites -notcontains $_) {
              $arrVMsAtBothSites += $_
            }
          }
          Else {
            # If site B VM is in site A VM DRS Group, remove from site A VM DRS Group.
            If ($objSiteADrsGroup.Vm -contains $_.ExtensionData.MoRef) {
              If ($PSCmdlet.ShouldProcess($_)) {
                Remove-VMFromDrsGroup -Cluster $objCluster -DrsGroup $objSiteADrsGroup -VM $_
              }
              $arrSiteARemoved += $_
            }
            # If site B VM is not in site B VM DRS Group, add to site B VM DRS Group.
            If ($objSiteBDrsGroup.Vm -notcontains $_.ExtensionData.MoRef) {
              If ($PSCmdlet.ShouldProcess($_)) {
                Add-VMToDrsGroup -Cluster $objCluster -DrsGroup $objSiteBDrsGroup -VM $_
              }
              $arrSiteBAdded += $_
            }
          }   
        }
      
        # Output summary of VMs added to and removed from site A and B VM DRS Groups.
        Write-Host "-------------------------------------------------"
        Write-Host "Updated VM DRS Groups for cluster ""$($objCluster.Name)"""
        Write-Host "-------------------------------------------------`n"
      
        Write-Host "DRS Group ""$SiteADrsGroup"""
        Write-Host "---------------"
        Write-Host "$($arrSiteAAdded.Count) VMs added." 
        $arrSiteAAdded | Sort | ForEach {Write-Host $_}
        Write-Host ""
        Write-Host "$($arrSiteARemoved.Count) VMs removed." 
        $arrSiteARemoved | Sort | ForEach {Write-Host $_}
        Write-Host ""
      
        Write-Host "DRS Group ""$SiteBDrsGroup"""
        Write-Host "---------------"
        Write-Host "$($arrSiteBAdded.Count) VMs added." 
        $arrSiteBAdded | Sort | ForEach {Write-Host $_}
        Write-Host ""
        Write-Host "$($arrSiteBRemoved.Count) VMs removed." 
        $arrSiteBRemoved | Sort | ForEach {Write-Host $_}
        Write-Host ""
      }
    }
  }
  
  End {
    # Write-warning if array of VMs using datastores at both sites is not empty.
    If ($arrVMsAtBothSites.Count -gt 0) {
      Write-Warning "$($arrVMsAtBothSites.Count) VMs using datastores at both sites."
      $arrVMsAtBothSites | Sort | ForEach {Write-Host $_}
    }
    Else {
      Write-Host "$($arrVMsAtBothSites.Count) VMs using datastores at both sites."
    }
  }
}