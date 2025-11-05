module "service_observability" {
  source       = "./modules/service_observability"
  service_name = "self-service-observability"
  env          = "dev"
  splunk_realm = var.splunk_realm
}

output "dashboard_id" {
  description = "ID of the created dashboard."
  value       = module.service_observability.dashboard_id
}

output "dashboard_url" {
  description = "URL to the created dashboard."
  value       = module.service_observability.dashboard_url
}

output "chart_id" {
  description = "ID of the created chart."
  value       = module.service_observability.chart_id
}

output "dashboard_group_id" {
  description = "ID of the dashboard group."
  value       = module.service_observability.dashboard_group_id
}
