Function Update-VMHostPatch {
<#
  .SYNOPSIS
  Update VMHost with patch

  .DESCRIPTION
  Update VMHost with patch

  .PARAMETER VMHost
  A vSphere ESXi Host object

  .PARAMETER Path
  Path to update file

  .INPUTS
  Input Object Type, e.g. System.Management.Automation.PSObject

  .OUTPUTS
  None

  .EXAMPLE
  PS> Update-VMHostPatch -VMHost ESXi01,ESXi02 -HostPath /vmfs/volumes/datastore/folder/update.zip
  
  .EXAMPLE
  PS> Get-VMHost ESXi01,ESXi02 | Update-VMHostPatch -HostPath /vmfs/volumes/datastore/folder/update.zip

  .NOTES
  Version: 1.0 - Initial version
  Date: 2014-02-27
  Author: Richard Lock
  Tag: esxcli,host,patch,update
#>
  [CmdletBinding()]

  Param (
    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,
        
    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$HostPath 
  )    

  Begin {
  }
    
  Process {
    Try {
      ForEach ($objVMHost in $VMHost) {
        If ($objVMHost.GetType().Name -eq "string") {
          Try {
            $objVMHost = Get-VMHost $objVMHost -ErrorAction Stop
          }
          Catch [Exception] {
            Write-Warning "VMHost $objVMHost does not exist."
            Continue
          }
        }
        ElseIf ($objVMHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]) {
          Write-Warning "You did not pass a string or a VMHost object."
          Continue
        }
        
        # Put host in maintenance mode if it is not already
        Write-Output "Entering maintenance mode for host ""$objVMHost""..."
        Set-VMHost -VMHost $objVMHost -State Maintenance -Evacuate:$true

        # Apply update from specified path to host
        Write-Output "Applying update ""$HostPath"" to host ""$objVMHost""..."
        $objEsxCli = Get-EsxCli -VMHost $objVMHost
        $objEsxCli.software.vib.update($HostPath)
        
        # Restart host
        Write-Output "Restarting host ""$objVMHost""..."
        Restart-VMHost -VMHost $objVMHost -Confirm:$false

        # Wait for host to show as not responding
        Do {
          Write-Output "Waiting for host ""$objVMHost"" to show as not responding..."
          Start-Sleep 30
        }
        While ((Get-VMHost $objVMHost).ConnectionState -ne "NotResponding")

        # Wait for host to restart
        Do {
          Write-Output "Waiting for host ""$objVMHost"" to restart..."
          Start-Sleep 60
        }
        While ((Get-VMHost $objVMHost).ConnectionState -ne "Maintenance")

        # Exit maintenance mode for host
        Write-Output "Exiting maintenance mode for host ""$objVMHost""..."
        Set-VMHost -VMHost (Get-VMHost $objVMHost) -State Connected
      }
    }
    Catch [Exception] {
      Throw "Exception occurred during host update."
    }    
  }
  
  End {
  }
}