variable "location" {
  type    = string
  default = "eastus2"
}

variable "environment" {
  type    = string
  default = "dev"
}

# PoC smoke resource. Replace with actual cluster-bootstrap resources when
# wiring up to a real AKS cluster.
resource "terraform_data" "smoke" {
  input = var.environment
}

# ── Cluster bootstrap resources ───────────────────────────────────────────────
# Platform-layer K8s resources that every workload in this product depends on.
# Application deployments (Deployments, Services, Ingress) ship via Argo CD /
# Flux or dev-team pipelines — they do NOT live here.
#
# When wired to real AKS, uncomment remote.tf and use:
#   locals {
#     core    = data.terraform_remote_state.core.outputs
#     compute = data.terraform_remote_state.compute.outputs
#   }
#
# resource "helm_release" "ingress_nginx" { ... }
# resource "helm_release" "cert_manager" { ... }
# resource "kubernetes_namespace" "app" { ... }
# resource "kubernetes_cluster_role_binding" "app_team" { ... }
