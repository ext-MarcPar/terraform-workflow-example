# Outputs consumed by downstream layers via data "terraform_remote_state" "core".
# data/remote.tf, compute/remote.tf, workloads/remote.tf, and edge/remote.tf
# all read from these outputs. Add outputs here as new resources are added.

# ── Networking ────────────────────────────────────────────────────────────────
output "vnet_id" {
  description = "VNet resource ID."
  value       = "" # azurerm_virtual_network.main.id
}

output "pe_subnet_id" {
  description = "Private endpoint subnet ID."
  value       = "" # azurerm_subnet.pe.id
}

output "compute_subnet_id" {
  description = "Compute (AKS/App Service) subnet ID."
  value       = "" # azurerm_subnet.compute.id
}

output "agw_subnet_id" {
  description = "Application Gateway subnet ID."
  value       = "" # azurerm_subnet.agw.id
}

output "resource_group_name" {
  description = "Networking resource group name."
  value       = "" # azurerm_resource_group.net.name
}

# ── Observability ─────────────────────────────────────────────────────────────
output "laws_id" {
  description = "Log Analytics Workspace ARM resource ID (for diagnostic settings)."
  value       = "" # azurerm_log_analytics_workspace.main.id
}

output "laws_workspace_guid" {
  description = "Log Analytics Workspace GUID (for traffic analytics workspace_id)."
  value       = "" # azurerm_log_analytics_workspace.main.workspace_id
}

output "action_group_id" {
  description = "Monitor action group resource ID."
  value       = "" # azurerm_monitor_action_group.main.id
}

# ── Identity ──────────────────────────────────────────────────────────────────
output "workload_uami_id" {
  description = "Workload UAMI resource ID (for identity {} blocks on compute resources)."
  value       = "" # azurerm_user_assigned_identity.workload.id
}

output "workload_uami_principal_id" {
  description = "Workload UAMI principal ID (for role assignments in L2 Data)."
  value       = "" # azurerm_user_assigned_identity.workload.principal_id
}

output "workload_uami_client_id" {
  description = "Workload UAMI client ID (for workload identity federation in L4)."
  value       = "" # azurerm_user_assigned_identity.workload.client_id
}
