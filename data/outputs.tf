# Outputs consumed by compute/remote.tf and workloads/remote.tf.

output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = "" # azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI (for KV secret references in Container Apps)."
  value       = "" # azurerm_key_vault.main.vault_uri
}

output "acr_id" {
  description = "Container Registry resource ID."
  value       = "" # azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "Container Registry login server hostname."
  value       = "" # azurerm_container_registry.main.login_server
}

output "pg_server_id" {
  description = "PostgreSQL Flexible Server resource ID."
  value       = "" # azurerm_postgresql_flexible_server.main.id
}

output "pg_fqdn" {
  description = "PostgreSQL Flexible Server FQDN."
  value       = "" # azurerm_postgresql_flexible_server.main.fqdn
}
