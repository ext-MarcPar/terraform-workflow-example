variable "location"    { type = string }
variable "environment" { type = string }

locals {
  core    = data.terraform_remote_state.core.outputs
  compute = data.terraform_remote_state.compute.outputs
}

# ── Cluster bootstrap resources ───────────────────────────────────────────────
# Platform-layer K8s resources that every workload in this product depends on.
# Application deployments (Deployments, Services, Ingress) ship via Argo CD / Flux
# or dev-team pipelines — they do NOT live here.
#
# resource "helm_release" "ingress_nginx" { ... }
# resource "helm_release" "cert_manager" { ... }
# resource "kubernetes_namespace" "app" { ... }
# resource "kubernetes_cluster_role_binding" "app_team" { ... }
