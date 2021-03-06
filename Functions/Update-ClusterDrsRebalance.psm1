Function Update-ClusterDrsRebalance {
<#
  .SYNOPSIS
  Rebalance cluster DRS workload

  .DESCRIPTION
  Rebalance cluster DRS workload

  .PARAMETER Cluster
  A vSphere cluster object

  .INPUTS
  Input Object Type, e.g. System.Management.Automation.PSObject

  .OUTPUTS
  None

  .EXAMPLE
  PS> Update-ClusterDrsRebalance -Cluster ms-vcl-tst-01,ms-vcl-tst-02
  
  .EXAMPLE
  PS> Get-Cluster ms-vcl-tst-01,ms-vcl-tst-02 | Update-ClusterDrsRebalance

  .NOTES
  Version: 1.0 - Initial version
  Date: 2014-02-28
  Author: Richard Lock
  Tag: cluster,drs,rebalance
#>
  [CmdletBinding()]

  Param (
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Cluster
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
        
        # Get view object for cluster
        $objClusterView = Get-View -Id $objCluster.Id
        
        # Get existing cluster DRS threshold
        $intExistingVmotionRate = $null
        $intExistingVmotionRate = $objClusterView.ConfigurationEx.DrsConfig.VmotionRate

        # Reconfigure cluster DRS threshold
        $objClusterConfigSpec = New-Object VMware.Vim.ClusterConfigSpecEx
        $objClusterConfigSpec.DrsConfig = New-Object VMware.Vim.ClusterDrsConfigInfo
        $objClusterConfigSpec.DrsConfig.VmotionRate = 1
        Write-Output "Reconfiguring DRS threshold for cluster ""$objCluster"" to $($objClusterConfigSpec.DrsConfig.VmotionRate)..."
        $objClusterView.ReconfigureComputeResource_Task($objClusterConfigSpec, $true)
        
        # Refresh and apply DRS recommendations
        Write-Output "Refreshing and applying DRS recommendations for cluster ""$objCluster""..."
        Get-DrsRecommendation -Cluster $objCluster -Refresh | Apply-DrsRecommendation
        
        # Reset DRS threshold to original value, or 3 as a fallback
        If (($intExistingVmotionRate -ge 1) -and ($intExistingVmotionRate -le 5)) {
          $objClusterConfigSpec.DrsConfig.VmotionRate = $intExistingVmotionRate
        }
        Else {
          $objClusterConfigSpec.DrsConfig.VmotionRate = 3
        }
        Write-Output "Reconfiguring DRS threshold for cluster ""$objCluster"" to $($objClusterConfigSpec.DrsConfig.VmotionRate)..."
        $objClusterView.ReconfigureComputeResource_Task($objClusterConfigSpec, $true)
      }
    }
    Catch [Exception] {
      Throw "Exception occurred during cluster DRS rebalance."
    }    
  }
  
  End {
  }
}