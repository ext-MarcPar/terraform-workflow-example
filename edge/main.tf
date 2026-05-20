variable "location" {
  type    = string
  default = "eastus2"
}

variable "environment" {
  type    = string
  default = "dev"
}

# PoC smoke resource. Replace with actual Front Door / WAF resources when
# wiring up to a real subscription.
resource "terraform_data" "smoke" {
  input = var.environment
}

# ── Front Door Premium ────────────────────────────────────────────────────────
#
# When wired to real Azure, uncomment remote.tf and use:
#   locals {
#     core    = data.terraform_remote_state.core.outputs
#     compute = data.terraform_remote_state.compute.outputs
#   }
#
# resource "azurerm_cdn_frontdoor_profile" "main" {
#   sku_name = "Premium_AzureFrontDoor"
# }
# resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
#   # Use Microsoft Default Rule Set (DRS) 2.1 — not OWASP CRS.
#   managed_rule { type = "Microsoft_DefaultRuleSet" version = "2.1" action = "Block" }
#   managed_rule { type = "Microsoft_BotManagerRuleSet" version = "1.1" action = "Block" }
# }
# resource "azurerm_cdn_frontdoor_origin_group" "main" { ... }
# resource "azurerm_cdn_frontdoor_origin" "main" { ... }
# resource "azurerm_cdn_frontdoor_custom_domain" "main" { ... }
# resource "azurerm_cdn_frontdoor_route" "main" { ... }
