package terraform.azure.storage

import rego.v1

storage_accounts contains resource if {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    some action in resource.change.actions
    action in {"create", "update"}
}

deny contains msg if {
    resource := storage_accounts[_]
    not resource.change.after.https_traffic_only_enabled
    msg := sprintf("'%s': https_traffic_only_enabled must be true", [resource.address])
}

deny contains msg if {
    resource := storage_accounts[_]
    resource.change.after.min_tls_version != "TLS1_2"
    msg := sprintf("'%s': min_tls_version must be TLS1_2 (got '%s')", [resource.address, resource.change.after.min_tls_version])
}

deny contains msg if {
    resource := storage_accounts[_]
    resource.change.after.public_network_access_enabled != false
    msg := sprintf("'%s': public_network_access_enabled must be false", [resource.address])
}

deny contains msg if {
    resource := storage_accounts[_]
    resource.change.after.allow_nested_items_to_be_public != false
    msg := sprintf("'%s': allow_nested_items_to_be_public must be false", [resource.address])
}
