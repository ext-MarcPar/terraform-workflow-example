locals {
  # Pull upstream outputs once here; pass as variables into per-project sub-modules.
  # Sub-modules never access data.terraform_remote_state directly.
  core = data.terraform_remote_state.core.outputs

  tags = {
    environment = var.environment
    managed_by  = "terraform"
    tier        = "data"
  }
}

# ── Tier-shared resources (deploy first) ─────────────────────────────────────
# Resources every project in this tier consumes: Key Vault, ACR, PG server.
# These are NOT published Terraform modules — this is code organisation only.
#
# module "shared" {
#   source    = "./shared"
#   location  = var.location
#   tags      = local.tags
#
#   # Pass upstream outputs as variables — shared/ never reads remote state.
#   pe_subnet_id              = local.core.pe_subnet_id
#   resource_group_name       = local.core.resource_group_name
#   laws_id                   = local.core.laws_id
#   workload_uami_principal_id = local.core.workload_uami_principal_id
# }

# ── Per-project sub-modules ───────────────────────────────────────────────────
# Each sub-module receives everything it needs as input variables from here.
#
# module "project1" {
#   source    = "./project1"
#   location  = var.location
#   tags      = local.tags
#
#   pe_subnet_id = local.core.pe_subnet_id
#   key_vault_id = module.shared.key_vault_id   # from shared, not from remote state
#   pg_server_id = module.shared.pg_server_id
# }

# ── Key Vault ─────────────────────────────────────────────────────────────────
#
# resource "azurerm_key_vault" "main" {
#   name                          = "..."
#   resource_group_name           = local.core.resource_group_name
#   location                      = var.location
#   tenant_id                     = data.azurerm_client_config.current.tenant_id
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
