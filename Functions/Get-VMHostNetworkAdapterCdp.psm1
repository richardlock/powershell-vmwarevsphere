Function Get-VMHostNetworkAdapterCdp {
<#
  .SYNOPSIS
  Get CDP information for network adapters in the vSphere ESXi host

  .DESCRIPTION
  Get CDP information for network adapters in the vSphere ESXi host

  .PARAMETER VMHost
  A vSphere ESXi Host object

  .INPUTS
  Input Object Type, e.g. System.Management.Automation.PSObject

  .OUTPUTS
  Output Object Type, e.g System.Management.Automation.PSObject.

  .EXAMPLE
  PS> Get-VMHostNetworkAdapterCdp -VMHost ESXi01,ESXi02...

  .EXAMPLE
  PS> Get-VMHost ESXi01,ESXi02... | Get-VMHostNetworkAdapterCdp

  .NOTES
  Version: 1.0 - Initial version
  Date: 2014-03-25
  Author: Richard Lock
  Tag: cdp,host,network,nic,vmnic
#>
  [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

  Param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost
  )    

  Begin {
    $ErrorActionPreference = 'Stop'
    $objCdpInfo = @()
  }
 
  Process {
    Try {
      ForEach ($objVMHost in $VMHost) {
        If ($objVMHost.GetType().Name -eq "String") {
          Try {
            $objVMHost = Get-VMHost $objVMHost -ErrorAction Stop
          }
          Catch [Exception] {
            Write-Warning "VMHost $objVMHost does not exist"
            Continue
          }
        }
        ElseIf ($objVMHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]) {
          Write-Warning "You did not pass a string or a VMHost object"
          Continue
        }
                
        $objConfigManagerView = Get-View $objVMHost.ExtensionData.ConfigManager.NetworkSystem
        $objPhysicalNics = $objConfigManagerView.NetworkInfo.Pnic

        ForEach ($objPhysicalNic in $objPhysicalNics) {
          $objPhysicalNicHintInfo = $objConfigManagerView.QueryNetworkHint($objPhysicalNic.Device)
          If ($objPhysicalNicHintInfo.ConnectedSwitchPort) {
            $connected = $true
          }
          else {
            $connected = $false
          }

          $arrNicHintInfo = @{
            VMHost = $objVMHost.Name
            Nic = $objPhysicalNic.Device
            Connected = $connected
            Switch = $objPhysicalNicHintInfo.ConnectedSwitchPort.DevId
            PortId = $objPhysicalNicHintInfo.ConnectedSwitchPort.PortId
            ManagementAddress = $objPhysicalNicHintInfo.ConnectedSwitchPort.MgmtAddr
            HardwarePlatform = $objPhysicalNicHintInfo.ConnectedSwitchPort.HardwarePlatform
            SoftwareVersion = $objPhysicalNicHintInfo.ConnectedSwitchPort.SoftwareVersion
            Vlan = $objPhysicalNicHintInfo.ConnectedSwitchPort.Vlan
          }

          $objCdpInfo += New-Object PSObject -Property $arrNicHintInfo
        }
      }
    }
    Catch [Exception] {
      Throw "Unable to retrieve CDP info"
    }
  }
  
  End {
    Write-Output $objCdpInfo
  }
}