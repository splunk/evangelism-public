output "chart_id" {
  description = "Time chart ID."
  value       = module.charts.chart_id
}

output "dashboard_id" {
  description = "Dashboard ID."
  value       = module.dashboards.dashboard_id
}

output "dashboard_group_id" {
  description = "Dashboard group ID."
  value       = module.dashboards.dashboard_group_id
}

output "dashboard_url" {
  description = "Direct URL to the dashboard."
  value       = module.dashboards.dashboard_url
}

output "dashboard_name" {
  description = "Dashboard name."
  value       = module.dashboards.dashboard_name
}

output "dashboard_group_name" {
  description = "Dashboard group name."
  value       = module.dashboards.dashboard_group_name
}
