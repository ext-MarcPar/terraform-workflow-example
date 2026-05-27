package terraform.azure.keyvault

import rego.v1

key_vaults contains resource if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_key_vault"
    some action in resource.change.actions
    action in {"create", "update"}
}

deny contains msg if {
    resource := key_vaults[_]
    not resource.change.after.purge_protection_enabled
    msg := sprintf("'%s': purge_protection_enabled must be true", [resource.address])
}

deny contains msg if {
    resource := key_vaults[_]
    resource.change.after.public_network_access_enabled != false
    msg := sprintf("'%s': public_network_access_enabled must be false", [resource.address])
}

deny contains msg if {
    resource := key_vaults[_]
    not resource.change.after.enable_rbac_authorization
    msg := sprintf("'%s': enable_rbac_authorization must be true — access policies not permitted", [resource.address])
}

deny contains msg if {
    resource := key_vaults[_]
    resource.change.after.soft_delete_retention_days < 90
    msg := sprintf("'%s': soft_delete_retention_days must be >= 90 (got %d)", [resource.address, resource.change.after.soft_delete_retention_days])
}
