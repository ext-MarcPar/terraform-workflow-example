package terraform.azure.tags

import rego.v1

required_tags := {"environment", "managed_by", "product", "tier"}

affected_resources contains resource if {
    resource := input.resource_changes[_]
    some action in resource.change.actions
    action in {"create", "update"}
    startswith(resource.type, "azurerm_")
}

deny contains msg if {
    resource := affected_resources[_]
    tags := object.get(resource.change.after, "tags", {})
    missing := required_tags - {k | tags[k]}
    count(missing) > 0
    msg := sprintf("'%s' is missing required tags: %v", [resource.address, missing])
}
