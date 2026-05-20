locals {
  tags = {
    environment = var.environment
    managed_by  = "terraform"
    tier        = "data"
  }
}

# PoC smoke resource. Replace with actual azurerm resources when wiring up
# to a real subscription. Upstream core outputs should be passed via
# data "terraform_remote_state" "core" once the azurerm backend is active.
resource "terraform_data" "smoke" {
  input = var.environment
}

# ── Tier-shared resources ─────────────────────────────────────────────────────
#
# When wired to real Azure, uncomment remote.tf and use local.core:
#   locals { core = data.terraform_remote_state.core.outputs }
#
# module "shared" {
#   source    = "./shared"
#   location  = var.location
#   tags      = local.tags
#   pe_subnet_id               = local.core.pe_subnet_id
#   resource_group_name        = local.core.resource_group_name
#   laws_id                    = local.core.laws_id
#   workload_uami_principal_id = local.core.workload_uami_principal_id
# }

# ── Key Vault ─────────────────────────────────────────────────────────────────
#
# resource "azurerm_key_vault" "main" {
#   name                          = "..."
#   resource_group_name           = local.core.resource_group_name
#   location                      = var.location
#   sku_name                      = "standard"
#   purge_protection_enabled      = true
#   soft_delete_retention_days    = 90
#   public_network_access_enabled = false
#   enable_rbac_authorization     = true
#   tags                          = local.tags
# }
#
# resource "azurerm_role_assignment" "workload_kv_secrets_user" {
#   scope                = azurerm_key_vault.main.id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = local.core.workload_uami_principal_id
#   principal_type       = "ServicePrincipal"
# }

# ── Container Registry ────────────────────────────────────────────────────────
# resource "azurerm_container_registry" "main" { ... }

# ── PostgreSQL Flexible Server ────────────────────────────────────────────────
# resource "azurerm_postgresql_flexible_server" "main" { ... }

# ── Private Endpoints ─────────────────────────────────────────────────────────
# resource "azurerm_private_endpoint" "kv" { ... }
# resource "azurerm_private_endpoint" "acr" { ... }
# resource "azurerm_private_endpoint" "pg" { ... }
