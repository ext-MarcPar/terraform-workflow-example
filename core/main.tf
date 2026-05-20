locals {
  prefix = "${var.environment}${var.bu_code}${var.product_name}"
  tags = {
    environment = var.environment
    bu          = var.bu_code
    product     = var.product_name
    managed_by  = "terraform"
    tier        = "core"
  }
}

# PoC smoke resource — demonstrates the plan → apply → release flow without
# real Azure infrastructure. Replace with actual azurerm resources when wiring
# up to a real subscription.
resource "terraform_data" "smoke" {
  input = local.prefix
}

# ── Networking ────────────────────────────────────────────────────────────────
#
# resource "azurerm_resource_group" "net" {
#   name     = "${local.prefix}net01-rg"
#   location = var.location
#   tags     = local.tags
#   lifecycle { prevent_destroy = true }
# }
#
# resource "azurerm_virtual_network" "main" { ... }
# resource "azurerm_subnet" "pe" { ... }
# resource "azurerm_subnet" "compute" { ... }
# resource "azurerm_subnet" "agw" { ... }
# resource "azurerm_network_security_group" "pe" { ... }
# resource "azurerm_network_security_group" "compute" { ... }
# module "core_nsg_diagnostic" { ... }
# module "flow_logs" { ... }

# ── Observability ─────────────────────────────────────────────────────────────
#
# resource "azurerm_log_analytics_workspace" "main" {
#   name                = "${local.prefix}laws01"
#   resource_group_name = azurerm_resource_group.net.name
#   location            = var.location
#   sku                 = "PerGB2018"
#   retention_in_days   = 90
#   tags                = local.tags
# }
#
# resource "azurerm_monitor_action_group" "main" { ... }

# ── Identity ──────────────────────────────────────────────────────────────────
# UAMIs live in L1 Core so their principal_id is known before any compute
# resource exists, enabling role assignments in L2 without chicken-and-egg issues.
#
# resource "azurerm_user_assigned_identity" "workload" {
#   name                = "${local.prefix}workloaduami01"
#   resource_group_name = azurerm_resource_group.net.name
#   location            = var.location
#   tags                = local.tags
# }
