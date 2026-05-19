variable "location" {
  type        = string
  description = "Primary Azure region (e.g. eastus2)."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "environment must be dev, uat, or prd."
  }
}

variable "bu_code" {
  type        = string
  description = "2-character BU code (e.g. ct, on)."
}

variable "product_name" {
  type        = string
  description = "Product name with instance suffix (e.g. example01)."
}

variable "tenant_id" {
  type        = string
  description = "Entra ID tenant ID."
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space CIDR(s)."
}

variable "alert_email" {
  type        = string
  description = "Email address for monitoring action group alerts."
}
