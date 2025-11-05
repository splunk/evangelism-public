variable "service_name" {
  description = "Logical service name used for titles and grouping."
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "chart_id" {
  description = "ID of the chart to include in the dashboard."
  type        = string
}

variable "splunk_realm" {
  description = "Splunk Observability Cloud realm (e.g., us0, us1, eu0)."
  type        = string
}
