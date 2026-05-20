# ── PoC mode: remote state reads disabled ─────────────────────────────────────
# To wire up to real Azure, restore backend "azurerm" in versions.tf, then
# uncomment below and add `locals { core = ..., compute = ... }` to main.tf.

# locals {
#   state_backend = { ... }
#   bu_code      = "ct"
#   product_name = "example01"
# }
#
# data "terraform_remote_state" "core" { ... }
# data "terraform_remote_state" "data" { ... }
# data "terraform_remote_state" "compute" { ... }
