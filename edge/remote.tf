# ── PoC mode: remote state reads disabled ─────────────────────────────────────
# L5 Edge depends on L3 Compute (for origin endpoint IDs).
# To wire up to real Azure, restore backend "azurerm" in versions.tf, then
# uncomment below and add `locals { core = ..., compute = ... }` to main.tf.

# locals {
#   state_backend = { ... }
#   bu_code      = "ct"
#   product_name = "example01"
# }
#
# data "terraform_remote_state" "core" { ... }
# data "terraform_remote_state" "compute" { ... }
