Function Add-VMToDrsGroup {
<#
.SYNOPSIS
Adds a virtual machine to a cluster VM DRS Group.

.DESCRIPTION
Adds a virtual machine to a cluster VM DRS Group.

.PARAMETER Cluster
Specify the cluster for which you want to retrieve the VM DRS Group.

.PARAMETER DrsGroup
Specify the DRS group you want to retrieve.

.PARAMETER VM
Specify the virtual machine you want to add to the VM DRS Group.

.EXAMPLE
Add-VMToDrsGroup -Cluster "Cluster" -DrsGroup "VM DRS Group" -VM "VM"
Adds virtual machine "VM" to the DRS group "VM DRS Group" in cluster "Cluster".

.EXAMPLE
Get-Cluster "Cluster" | Get-VM "A*" | Add-VMToDrsGroup -Cluster "Cluster" -DrsGroup "VM DRS Group"
Adds all virtual machines with a name starting with "A" in cluster "Cluster" to the DRS group "VM DRS Group" of cluster "Cluster".

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
            If ($DrsGroup.Vm -contains $VM.ExtensionData.MoRef) {
              Write-Verbose "The DRS Group ""$strDrsGroupName"" in cluster ""$($Cluster.Name)"" already contains VM ""$VM""."
            }
            Else {
              $objSpec = New-Object VMware.Vim.ClusterConfigSpecEx
              $objSpec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1)
              $objSpec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec
              $objSpec.groupSpec[0].operation = "edit"
              $objSpec.groupSpec[0].info = $DrsGroup
              $objSpec.groupSpec[0].info.vm += $VM.ExtensionData.MoRef
              If ($PSCmdlet.ShouldProcess($VM)) {
                  Write-Verbose "Adding VM ""$VM"" to DRS Group ""$strDrsGroupName"" in cluster ""$Cluster""."
                  $Cluster.ExtensionData.ReconfigureComputeResource_Task($objSpec, $true)
              }
            }
          }
        }
      }
    }
  }
}