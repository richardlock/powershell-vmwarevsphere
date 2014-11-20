Function Remove-VMFromDrsGroup {
<#
.SYNOPSIS
Removes a virtual machine from a cluster VM DRS Group.

.DESCRIPTION
Removes a virtual machine from a cluster VM DRS Group.

.PARAMETER Cluster
Specify the cluster for which you want to retrieve the VM DRS Group.

.PARAMETER DrsGroup
Specify the VM DRS Group you want to retrieve.

.PARAMETER VM
Specify the virtual machine you want to remove from the VM DRS Group.

.EXAMPLE
Remove-VMFromDrsGroup -Cluster "Cluster" -DrsGroup "VM DRS Group" -VM "VM"
Removes virtual machine "VM" from the DRS group "VM DRS Group" of cluster "Cluster".

.EXAMPLE
Get-Cluster "Cluster" | Get-VM "A*" | Remove-VMFromDrsGroup -Cluster "Cluster" -DrsGroup "VM DRS Group"
Removes all virtual machines with a name starting with "A" in cluster "Cluster" from the DRS group "VM DRS Group" of cluster "Cluster".

.INPUTS
VirtualMachineImpl

.OUTPUTS
Task

.COMPONENT
VMware vSphere PowerCLI
#>
  
  [CmdletBinding (
    SupportsShouldProcess=$true
  )]
  
  Param (
    [parameter(Mandatory=$true)] $Cluster,
    [parameter(Mandatory=$true)] $DrsGroup,
    [parameter(Mandatory=$true, ValueFromPipeline=$true)] $VM
  )

  Process {
    $Cluster = Get-Cluster -Name $Cluster
    If ($Cluster) {
      If ($DrsGroup.GetType().Name -eq "string") {
        $strDrsGroupName = $DrsGroup
        $DrsGroup = Get-DrsGroup -Cluster $Cluster -Name $DrsGroup -Type "ClusterVmGroup"
      }
      If (-not $DrsGroup) {
        Write-Error "The DRS Group ""$strDrsGroupName"" was not found in cluster ""$($Cluster.name)""."
      }
      Else { 
        If ($DrsGroup.GetType().Name -ne "ClusterVmGroup") {
          Write-Error "The DRS Group ""$strDrsGroupName"" in cluster ""$($Cluster.Name)"" does not have the required type ""ClusterVmGroup""."
        }
        Else {
          $VM = $Cluster | Get-VM -Name $VM
          If ($VM) {
            If ($DrsGroup.Vm -notcontains $VM.ExtensionData.MoRef) {
              Write-Verbose "The DRS Group ""$strDrsGroupName"" in cluster ""$($Cluster.Name)"" does not contain VM ""$VM""."
            }
            Else {
              $objSpec = New-Object VMware.Vim.ClusterConfigSpecEx
              $objSpec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1)
              $objSpec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec
              $objSpec.groupSpec[0].operation = "edit"
              $objSpec.groupSpec[0].info = $DrsGroup
              $objSpec.groupSpec[0].info.vm = ($Cluster.ExtensionData.ConfigurationEx.Group | Where {$_.Name -eq $DrsGroup.Name}).VM | Where {$_ -ne $VM.ExtensionData.MoRef}
              If ($PSCmdlet.ShouldProcess($VM)) {
                Write-Verbose "Removing VM ""$VM"" from DRS Group ""$strDrsGroupName"" in cluster ""$Cluster""."
                $Cluster.ExtensionData.ReconfigureComputeResource_Task($objSpec, $true)
              }
            }
          }
        }
      }
    }
  }
}