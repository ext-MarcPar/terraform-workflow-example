output "aks_cluster_id" {
  description = "AKS cluster resource ID."
  value       = "" # azurerm_kubernetes_cluster.main.id
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = "" # azurerm_kubernetes_cluster.main.name
}

output "app_service_id" {
  description = "App Service resource ID (if using App Service instead of AKS)."
  value       = "" # azurerm_linux_web_app.main.id
}
