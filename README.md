Introduction
============

This is a set of PowerShell cmdlets for use with VMware vSphere.  It includes a module manifest "VMwarevSphere.psd1" which references the modules in the "Functions" subdirectory.  Each module is a single cmdlet.  The DRS group cmdlets are based on code from Luc Dekens, but with some modifications required for the "Update-ClusterVMDrsGroups" cmdlet.

To get started, run "Import-Module VMwarevSphere" to import the module into a PowerCLI session.

DRS cmdlets
===========

To simplify the process of managing VM site affinity using DRS Groups/Rules, the cmdlet "Update-ClusterVMDrsGroups" can be scheduled or run ad hoc to correct any missing/misconfigured VM DRS Groups.

Just download the PowerShell module/functions, and run the “Update-ClusterVMDrsGroups” cmdlet against one or more clusters after connecting to the “vc-prd-da01” vCenter.  E.g.

Dry run:      Get-Cluster clustername | Update-ClusterVMDrsGroups -WhatIf
Actual:       Get-Cluster clustername | Update-ClusterVMDrsGroups

Background

Due to us having a stretched VMware cluster using MetroCluster storage, we need a way to manage site affinity for VMs/vApps.  MetroCluster volumes are site specific, so under normal operation VMs located on KR NFS datastores should run on KR hosts, and likewise for VMs located at MS.

When VMs are migrated into the new vCenter, they need adding to the appropriate VM DRS Group for the cluster they are in.  E.g.

KR Non-Production VMs
MS Non-Production VMs

KR Production VMs
MS Production VMs

KR Management VMs
MS Management VMs

To simplify this process and reduce human error, I’ve written a new PS cmdlet based on some DRS cmdlets written by Luc Dekens (there are no native cmdlets yet to manage DRS Groups).  I’ve extended these to add in some extra parameters and error control, then created the main cmdlet to ensure DRS Group membership is correct based on the datastore a VM is located on.  It removes a VM from an incorrect group and adds to the correct group.  It also checks that VMs are not using datastores at both sites, and will display a warning message if any are found.  Another approach is to manage DRS site affinity using tags, but the approach used here is automated based on a VM’s physical MetroCluster location.  The default parameters to identify sites and DRS rules at either site can be modified at runtime or permanently for use with different site names.
