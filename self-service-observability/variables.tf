variable "splunk_realm" {
  description = "Splunk Observability Cloud realm (e.g., us0, us1, eu0)"
  type        = string
  default     = "us1"

  validation {
    condition     = contains(["us0", "us1", "eu0", "eu1", "au0", "jp0"], var.splunk_realm)
    error_message = "Realm must be a valid Splunk Observability Cloud realm: us0, us1, eu0, eu1, au0, or jp0."
  }
}

variable "signalfx_access_token" {
  description = "Splunk Observability Cloud access token for managing resources (not the ingest token)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.signalfx_access_token) > 0
    error_message = "Access token must not be empty."
  }
}
