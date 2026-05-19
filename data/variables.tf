variable "location" {
  type        = string
  description = "Primary Azure region."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
  validation {
    condition     = contains(["dev", "uat", "prd"], var.environment)
    error_message = "environment must be dev, uat, or prd."
  }
}
