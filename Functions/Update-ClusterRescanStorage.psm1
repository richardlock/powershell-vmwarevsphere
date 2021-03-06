Function Update-ClusterRescanStorage {
<#
  .SYNOPSIS
  Rescan storage on all hosts in a cluster

  .DESCRIPTION
  Rescan storage on all hosts in a cluster

  .PARAMETER Cluster
  A vSphere cluster object

  .PARAMETER RescanHba
  String specifying all HBAs or type of HBA to rescan 
  
  .PARAMETER RescanVmfs
  Boolean specifying whether to rescan VMFS

  .INPUTS
  Input Object Type, e.g. System.Management.Automation.PSObject

  .OUTPUTS
  None

  .EXAMPLE
  PS> Update-ClusterRescanStorage -Cluster ms-vcl-tst-01,ms-vcl-tst-02 -RescanHba:All
  
  .EXAMPLE
  PS> Get-Cluster ms-vcl-tst-01,ms-vcl-tst-02 | Update-ClusterRescanStorage -RescanHba:iSCSI -RescanVmfs:$true

  .NOTES
  Version: 1.0 - Initial version
  Date: 2014-02-28
  Author: Richard Lock
  Tag: cluster,fibrechannel,iscsi,rescan,storage
#>
  [CmdletBinding()]

  Param (
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Cluster,
        
    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$RescanHba,
    
    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Bool]$RescanVmfs
  )    

  Begin {
  }
    
  Process {
    Try {
      ForEach ($objCluster in $Cluster) {
        If ($objCluster.GetType().Name -eq "string") {
          Try {
            $objCluster = Get-Cluster $objCluster -ErrorAction Stop
          }
          Catch [Exception] {
            Write-Warning "Cluster $objCluster does not exist."
            Continue
          }
        }
        ElseIf ($objCluster -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ClusterImpl]) {
          Write-Warning "You did not pass a string or a cluster object."
          Continue
        }
        
        If (!$RescanHba -and !$RescanVmfs) {
          Write-Warning "Please specify whether to rescan HBA and/or VMFS."
        }
        
        # Get all hosts in the cluster
        $objVMHosts = Get-VMHost -Location $objCluster | Sort Name

        # If specified, rescan all HBAs or a particular type of HBA on all hosts in the cluster
        If (($RescanHba -ne $null) -and ($RescanHba -ne "")) {
          Switch ($RescanHba) {
            All {
              ForEach ($objVMHost In $objVMHosts) {
                Write-Output "Rescanning all HBAs on host ""$objVMHost""..."
                Try {
                  Get-VMHostStorage -VMHost $objVMHost -RescanAllHba
                }
                Catch {
                  Write-Warning "Exception occurred while rescanning all HBAs on host ""$objVMHost""..."
                  Continue
                }
              }
            }
            {($_ -eq "Block") -or ($_ -eq "FibreChannel") -or ($_ -eq "iSCSI") -or ($_ -eq "ParallelSCSI")} {
              ForEach ($objVMHost In $objVMHosts) {
                Write-Output "Rescanning all $RescanHba HBAs on host ""$objVMHost""..."
                ForEach ($objVMHostHba In (Get-VMHostHba -VMHost $objVMHost -Type $RescanHba)) {
                  (Get-View -Id (($objVMHost | Get-View).ConfigManager.StorageSystem)).RescanHba($objVMHostHba)
                }
              }
            }
            Default {
              Write-Warning "Invalid HBA type specfied to rescan."
            }
          }
        }
	      
        # If specified, rescan VMFS on all hosts in the cluster
        If ($RescanVmfs) {
          ForEach ($objVMHost In $objVMHosts) {
            Write-Output "Rescanning VMFS on host ""$objVMHost""..."
            Get-VMHostStorage -VMHost $objVMHost -RescanVmfs
          }
        }
      }
    }
    Catch [Exception] {
      Throw "Exception occurred during cluster storage rescan."
    }    
  }
  
  End {
  }
}