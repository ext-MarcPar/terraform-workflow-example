# Optional layer — skip for App Service / VM products that manage workloads via
# their own CI/CD pipeline. For AKS products, this holds cluster-bootstrap
# resources: ingress controller, cert-manager, base namespaces + RBAC.

terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
  }
  backend "local" {}
}
