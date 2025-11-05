variable "service_name" {
  description = "Logical service name used for dimensions, titles, and grouping."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "Service name must be lowercase alphanumeric with hyphens only."
  }

  validation {
    condition     = length(var.service_name) <= 64
    error_message = "Service name must be 64 characters or less."
  }
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "splunk_realm" {
  description = "Splunk Observability Cloud realm (e.g., us0, us1, eu0)."
  type        = string

  validation {
    condition     = contains(["us0", "us1", "eu0", "eu1", "au0", "jp0"], var.splunk_realm)
    error_message = "Realm must be a valid Splunk Observability Cloud realm."
  }
}
