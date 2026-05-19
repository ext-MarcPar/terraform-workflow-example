variable "location"    { type = string }
variable "environment" { type = string }

locals {
  core = data.terraform_remote_state.core.outputs
  data = data.terraform_remote_state.data.outputs
  tags = { environment = var.environment, managed_by = "terraform", tier = "compute" }
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────
#
# resource "azurerm_kubernetes_cluster" "main" {
#   ...
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [local.core.workload_uami_id]
#   }
#   default_node_pool {
#     vnet_subnet_id = local.core.compute_subnet_id
#     ...
#   }
# }
#
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   scope                = local.data.acr_id
#   role_definition_name = "AcrPull"
#   principal_id         = local.core.workload_uami_principal_id
#   principal_type       = "ServicePrincipal"
# }

# ── App Service Plan (alternative to AKS) ─────────────────────────────────────
# resource "azurerm_service_plan" "main" { ... }
# resource "azurerm_linux_web_app" "main" { ... }
