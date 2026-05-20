variable "location" {
  type        = string
  description = "Primary Azure region (e.g. eastus2)."
  default     = "eastus2"
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  default     = "dev"
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "environment must be dev, uat, or prd."
  }
}

variable "bu_code" {
  type        = string
  description = "2-character BU code (e.g. ct, on)."
  default     = "ex"
}

variable "product_name" {
  type        = string
  description = "Product name with instance suffix (e.g. example01)."
  default     = "poc01"
}

variable "tenant_id" {
  type        = string
  description = "Entra ID tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "address_space" {
  type        = list(string)
  description = "VNet address space CIDR(s)."
  default     = ["10.0.0.0/16"]
}

variable "alert_email" {
  type        = string
  description = "Email address for monitoring action group alerts."
  default     = "ops@example.com"
}
