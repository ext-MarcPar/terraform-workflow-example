variable "location"    { type = string }
variable "environment" { type = string }

locals {
  core    = data.terraform_remote_state.core.outputs
  compute = data.terraform_remote_state.compute.outputs
}

# ── Front Door Premium ────────────────────────────────────────────────────────
#
# resource "azurerm_cdn_frontdoor_profile" "main" {
#   name                = "..."
#   resource_group_name = local.core.resource_group_name
#   sku_name            = "Premium_AzureFrontDoor"
# }
#
# resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
#   name                = "..."
#   resource_group_name = local.core.resource_group_name
#   sku_name            = "Premium_AzureFrontDoor"
#   mode                = "Prevention"
#   # Use Microsoft Default Rule Set (DRS) 2.1 — not OWASP CRS.
#   managed_rule { type = "Microsoft_DefaultRuleSet" version = "2.1" action = "Block" }
#   managed_rule { type = "Microsoft_BotManagerRuleSet" version = "1.1" action = "Block" }
# }
#
# resource "azurerm_cdn_frontdoor_origin_group" "main" { ... }
#
# resource "azurerm_cdn_frontdoor_origin" "main" {
#   # origin_host_header = computed from compute outputs
#   # e.g. "${data.terraform_remote_state.compute.outputs.app_service_name}.azurewebsites.net"
# }
#
# resource "azurerm_cdn_frontdoor_custom_domain" "main" { ... }
# resource "azurerm_cdn_frontdoor_route" "main" { ... }
